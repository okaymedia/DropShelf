import Foundation
import XCTest
@testable import DropShelf

@MainActor
final class ShelfStoreTests: XCTestCase {
    func testAddDedupeReorderRemoveAndReload() throws {
        let base = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: base) }
        let first = base.appendingPathComponent("first")
        let second = base.appendingPathComponent("second")
        try Data().write(to: first)
        try Data().write(to: second)
        let persistence = try PersistenceService(baseURL: base)
        let store = try ShelfStore(persistence: persistence)
        try store.add(urls: [first, second, first])
        XCTAssertEqual(store.items.map(\.displayName), ["first", "second"])
        store.move(fromOffsets: IndexSet(integer: 0), toOffset: 2)
        XCTAssertEqual(store.items.map(\.displayName), ["second", "first"])
        store.remove(ids: [store.items[0].id])
        XCTAssertTrue(FileManager.default.fileExists(atPath: second.path))
        try store.save()
        let reloaded = try ShelfStore(persistence: persistence)
        XCTAssertEqual(reloaded.items.map(\.displayName), ["first"])
        reloaded.clear()
        try reloaded.save()
        XCTAssertTrue(try persistence.load().isEmpty)
    }

    func testMissingAndRelocate() throws {
        let base = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: base) }
        let original = base.appendingPathComponent("original")
        let replacement = base.appendingPathComponent("replacement")
        try Data().write(to: original)
        let store = try ShelfStore(persistence: PersistenceService(baseURL: base))
        try store.add(urls: [original])
        let id = try XCTUnwrap(store.items.first?.id)
        XCTAssertEqual(store.status(for: try XCTUnwrap(store.items.first)), .ok)
        try FileManager.default.removeItem(at: original)
        store.refreshStatuses()
        XCTAssertEqual(store.status(for: try XCTUnwrap(store.items.first)), .missing)
        try Data().write(to: replacement)
        try store.relocate(id: id, to: replacement)
        XCTAssertEqual(store.status(for: try XCTUnwrap(store.items.first)), .ok)
        XCTAssertEqual(store.items.first?.lastKnownPath, replacement.standardizedFileURL.path)
    }

    func testRenameTracking() throws {
        let base = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: base) }
        let original = base.appendingPathComponent("original")
        let renamed = base.appendingPathComponent("renamed")
        try Data().write(to: original)
        let store = try ShelfStore(persistence: PersistenceService(baseURL: base))
        try store.add(urls: [original])
        try FileManager.default.moveItem(at: original, to: renamed)
        store.refreshStatuses()
        XCTAssertEqual(store.items.first?.lastKnownPath, renamed.standardizedFileURL.path)
        XCTAssertEqual(store.items.first?.displayName, "renamed")
        XCTAssertEqual(store.status(for: try XCTUnwrap(store.items.first)), .ok)
    }

    func testDebouncedSave() async throws {
        let base = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: base) }
        let file = base.appendingPathComponent("item")
        try Data().write(to: file)
        let persistence = try PersistenceService(baseURL: base)
        let store = try ShelfStore(persistence: persistence)
        try store.add(urls: [file])
        try await Task.sleep(for: .milliseconds(700))
        XCTAssertEqual(try persistence.load().map(\.displayName), ["item"])
    }

    func testSortAndPersistOrderAndPreference() throws {
        let base = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: base) }
        let suite = "DropShelfTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let names = ["z.txt", "a.pdf", "m.txt", "missing.dat"]
        let urls = names.map { base.appendingPathComponent($0) }
        for url in urls { try Data().write(to: url) }
        let persistence = try PersistenceService(baseURL: base)
        let store = try ShelfStore(persistence: persistence, defaults: defaults)
        for url in urls { try store.add(urls: [url]) }
        try FileManager.default.removeItem(at: urls[3])
        store.refreshStatuses()
        for (key, ascending, expected) in [
            (ShelfStore.SortKey.name, true, ["a.pdf", "m.txt", "z.txt", "missing.dat"]),
            (.name, false, ["z.txt", "m.txt", "a.pdf", "missing.dat"]),
            (.dateAdded, true, ["z.txt", "a.pdf", "m.txt", "missing.dat"]),
            (.dateAdded, false, ["m.txt", "a.pdf", "z.txt", "missing.dat"]),
            (.kind, true, ["a.pdf", "m.txt", "z.txt", "missing.dat"]),
            (.kind, false, ["m.txt", "z.txt", "a.pdf", "missing.dat"])
        ] {
            store.sort(by: key, ascending: ascending)
            XCTAssertEqual(store.items.map(\.displayName), expected)
        }
        try store.save()
        let reloaded = try ShelfStore(persistence: persistence, defaults: defaults)
        XCTAssertEqual(reloaded.items.map(\.displayName), store.items.map(\.displayName))
        XCTAssertEqual(reloaded.sortKey, .kind)
        XCTAssertFalse(reloaded.sortAscending)
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
