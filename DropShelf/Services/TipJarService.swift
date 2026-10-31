import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class TipJarService {
    enum State: Equatable {
        case loading
        case ready(String)
        case purchasing
        case thanks
        case failed(String)
        case unavailable
    }

    static let productID = "agency.okaymedia.DropShelf.tip.coffee"
    private(set) var state: State = .loading
    private var product: Product?
    @ObservationIgnored private let loadProducts: () async throws -> [Product]
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init(loadProducts: @escaping () async throws -> [Product] = {
        try await Product.products(for: [TipJarService.productID])
    }, listenForUpdates: Bool = true) {
        self.loadProducts = loadProducts
        if listenForUpdates {
            updatesTask = Task { [weak self] in
                for await result in Transaction.updates {
                    guard !Task.isCancelled else { break }
                    await self?.handle(result)
                }
            }
        }
    }

    func load() async {
        state = .loading
        do {
            let products = try await loadProducts()
            guard case .loading = state else { return }
            product = products.first { $0.id == Self.productID }
            if let product {
                state = .ready(product.displayPrice)
            } else {
                state = .unavailable
            }
        } catch {
            guard case .loading = state else { return }
            state = .failed(NSLocalizedString("Could not load the tip. Please try again.", comment: ""))
        }
    }

    func purchase() async {
        guard let product, case .ready = state else { return }
        state = .purchasing
        do {
            switch try await product.purchase() {
            case .success(let result):
                await handle(result)
            case .userCancelled, .pending:
                state = .ready(product.displayPrice)
            @unknown default:
                state = .ready(product.displayPrice)
            }
        } catch {
            state = .failed(NSLocalizedString("Purchase failed. Please try again.", comment: ""))
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            guard transaction.productID == Self.productID else { return }
            await transaction.finish()
            state = .thanks
        case .unverified(let transaction, _):
            guard transaction.productID == Self.productID else { return }
            state = .failed(NSLocalizedString("Could not verify the purchase. Please try again.", comment: ""))
        }
    }
}
