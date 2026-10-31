import Foundation
import XCTest
@testable import DropShelf

final class ModelPersistenceTests: XCTestCase {
    func testRoundTrip() throws {
        let base = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: base) }
        let service = try PersistenceService(baseURL: base)
        XCTAssertTrue(try service.load().isEmpty)
        let item = ShelfItem(bookmarkData: Data([1, 2, 3]), lastKnownPath: "/tmp/example", displayName: "example", isDirectory: false)
        try service.save([item])
        let loaded = try XCTUnwrap(service.load().first)
        XCTAssertEqual(loaded.id, item.id)
        XCTAssertEqual(loaded.bookmarkData, item.bookmarkData)
        XCTAssertEqual(loaded.lastKnownPath, item.lastKnownPath)
        XCTAssertEqual(loaded.displayName, item.displayName)
        XCTAssertEqual(loaded.isDirectory, item.isDirectory)
        XCTAssertEqual(loaded.addedAt, item.addedAt)
    }

    func testCorruptFileRecovery() throws {
        let base = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: base) }
        let directory = base.appendingPathComponent("DropShelf", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let corrupt = Data("invalid json".utf8)
        let file = directory.appendingPathComponent("shelf.json")
        try corrupt.write(to: file)
        let service = try PersistenceService(baseURL: base)
        XCTAssertTrue(try service.load().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        let backups = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let backup = try XCTUnwrap(backups.first { $0.lastPathComponent.hasPrefix("shelf.corrupt-") && $0.pathExtension == "json" })
        XCTAssertEqual(try Data(contentsOf: backup), corrupt)
        try service.save([])
        XCTAssertTrue(try service.load().isEmpty)
    }

    func testBookmarkCreateAndResolve() throws {
        let base = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: base) }
        let file = base.appendingPathComponent("example.txt")
        try Data("example".utf8).write(to: file)
        let service = BookmarkService()
        let data = try service.create(for: file)
        let resolved = try service.resolve(data)
        XCTAssertEqual(resolved.url.standardizedFileURL, file.standardizedFileURL)
        let refreshed = try service.refresh(data)
        XCTAssertEqual(try service.resolve(refreshed).url.standardizedFileURL, file.standardizedFileURL)
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
