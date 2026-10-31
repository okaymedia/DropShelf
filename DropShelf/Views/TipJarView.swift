import SwiftUI

struct TipJarView: View {
    let tipJar: TipJarService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Buy me a coffee ☕").font(.headline)
            Text("DropShelf is free and made by one developer.")
                .font(.callout).foregroundStyle(.secondary)
            switch tipJar.state {
            case .loading:
                ProgressView().controlSize(.small)
            case .ready(let price):
                Button(price) { Task { await tipJar.purchase() } }
            case .purchasing:
                ProgressView().controlSize(.small)
            case .thanks:
                Text("Thank you for supporting DropShelf!")
                    .foregroundStyle(.green)
                    .transition(.opacity)
            case .failed(let message):
                Text(message).foregroundStyle(.red)
                Button("Try Again") { Task { await tipJar.load() } }
            case .unavailable:
                Text("Tip jar is currently unavailable.").foregroundStyle(.secondary)
                Button("Try Again") { Task { await tipJar.load() } }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: tipJar.state)
    }
}
