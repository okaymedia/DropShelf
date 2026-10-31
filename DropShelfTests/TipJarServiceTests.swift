import XCTest
@testable import DropShelf

@MainActor
final class TipJarServiceTests: XCTestCase {
    func testMissingProductBecomesUnavailable() async {
        let service = TipJarService(loadProducts: { [] }, listenForUpdates: false)
        XCTAssertEqual(service.state, .loading)
        await service.load()
        XCTAssertEqual(service.state, .unavailable)
    }
}
