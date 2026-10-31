import Foundation

struct ShelfItem: Codable, Identifiable, Sendable {
    let id: UUID
    var bookmarkData: Data
    var lastKnownPath: String
    var displayName: String
    var isDirectory: Bool
    let addedAt: Date

    init(
        id: UUID = UUID(),
        bookmarkData: Data,
        lastKnownPath: String,
        displayName: String,
        isDirectory: Bool,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.bookmarkData = bookmarkData
        self.lastKnownPath = lastKnownPath
        self.displayName = displayName
        self.isDirectory = isDirectory
        self.addedAt = addedAt
    }
}

struct ShelfFile: Codable, Sendable {
    static let currentVersion = 1

    let version: Int
    var items: [ShelfItem]

    init(version: Int = Self.currentVersion, items: [ShelfItem]) {
        self.version = version
        self.items = items
    }
}
