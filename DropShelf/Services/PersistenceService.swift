import Foundation

struct PersistenceService {
    enum PersistenceError: Error {
        case unsupportedVersion(Int)
    }

    private let directoryURL: URL
    private var fileURL: URL { directoryURL.appendingPathComponent("shelf.json") }

    // An injected base URL is the Application Support directory's equivalent.
    init(baseURL: URL? = nil) throws {
        let base = try baseURL ?? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        directoryURL = base.appendingPathComponent("DropShelf", isDirectory: true)
    }

    func load() throws -> [ShelfItem] {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return []
        }

        let shelf: ShelfFile
        do {
            shelf = try JSONDecoder().decode(ShelfFile.self, from: data)
        } catch is DecodingError {
            try backupCorruptFile()
            return []
        }
        guard shelf.version == ShelfFile.currentVersion else {
            throw PersistenceError.unsupportedVersion(shelf.version)
        }
        return shelf.items
    }

    func save(_ items: [ShelfItem]) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(ShelfFile(items: items))
        try data.write(to: fileURL, options: .atomic)
    }

    private func backupCorruptFile() throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let backupURL = directoryURL.appendingPathComponent("shelf.corrupt-\(date)-\(UUID().uuidString).json")
        try FileManager.default.moveItem(at: fileURL, to: backupURL)
    }
}
