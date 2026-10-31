import Foundation

struct BookmarkService {
    func create(for url: URL) throws -> Data {
        do {
            return try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            return try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        }
    }

    func resolve(_ data: Data) throws -> (url: URL, isStale: Bool) {
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            return (url, isStale)
        } catch {
            isStale = false
            let url = try URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
            return (url, isStale)
        }
    }

    func refresh(_ data: Data) throws -> Data {
        let resolved = try resolve(data)
        guard resolved.isStale else { return data }
        let accessing = startAccessing(resolved.url)
        defer { if accessing { stopAccessing(resolved.url) } }
        return try create(for: resolved.url)
    }

    func startAccessing(_ url: URL) -> Bool {
        url.startAccessingSecurityScopedResource()
    }

    func stopAccessing(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
    }
}
