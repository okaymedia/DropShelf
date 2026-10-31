import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ShelfStore {
    enum SortKey: String, CaseIterable {
        case name, dateAdded, kind, size
    }

    enum Status: Equatable {
        case ok, missing, inaccessible
    }

    private(set) var items: [ShelfItem]
    private(set) var lastSaveError: Error?
    private(set) var sortKey: SortKey
    private(set) var sortAscending: Bool
    @ObservationIgnored private let defaults: UserDefaults
    private var statuses: [UUID: Status] = [:]
    @ObservationIgnored private let bookmarks: BookmarkService
    @ObservationIgnored private let persistence: PersistenceService
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init(persistence: PersistenceService, bookmarks: BookmarkService = BookmarkService(), defaults: UserDefaults = .standard) throws {
        self.defaults = defaults
        sortKey = SortKey(rawValue: defaults.string(forKey: "shelfSortKey") ?? "") ?? .name
        sortAscending = defaults.object(forKey: "shelfSortAscending") as? Bool ?? true
        self.persistence = persistence
        self.bookmarks = bookmarks
        items = try persistence.load()
        refreshStatuses()
    }

    func add(urls: [URL]) throws {
        var paths = Set(items.map { item in
            ((try? bookmarks.resolve(item.bookmarkData).url) ?? URL(fileURLWithPath: item.lastKnownPath))
                .standardizedFileURL.resolvingSymlinksInPath().path
        })
        var additions: [ShelfItem] = []
        for url in urls {
            let path = url.standardizedFileURL.resolvingSymlinksInPath().path
            guard paths.insert(path).inserted else { continue }
            let accessing = bookmarks.startAccessing(url)
            defer { if accessing { bookmarks.stopAccessing(url) } }
            let data = try bookmarks.create(for: url)
            var isDirectory: ObjCBool = false
            _ = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            additions.append(ShelfItem(bookmarkData: data, lastKnownPath: path,
                                       displayName: url.lastPathComponent, isDirectory: isDirectory.boolValue))
        }
        guard !additions.isEmpty else { return }
        items.append(contentsOf: additions)
        refreshStatuses()
        scheduleSave()
    }

    func remove(ids: Set<UUID>) {
        guard items.contains(where: { ids.contains($0.id) }) else { return }
        items.removeAll { ids.contains($0.id) }
        for id in ids { statuses.removeValue(forKey: id) }
        scheduleSave()
    }

    func clear() {
        guard !items.isEmpty else { return }
        items.removeAll()
        statuses.removeAll()
        scheduleSave()
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        guard !fromOffsets.isEmpty else { return }
        items.move(fromOffsets: fromOffsets, toOffset: toOffset)
        scheduleSave()
    }

    func sort(by key: SortKey, ascending: Bool) {
        sortKey = key
        sortAscending = ascending
        defaults.set(key.rawValue, forKey: "shelfSortKey")
        defaults.set(ascending, forKey: "shelfSortAscending")
        refreshStatuses()
        // Compute file metadata once, while the security-scoped URL is accessible.
        var sizes: [UUID: Int64] = [:]
        if key == .size {
            for item in items where !item.isDirectory && status(for: item) == .ok {
                guard let url = try? bookmarks.resolve(item.bookmarkData).url else { continue }
                let accessing = bookmarks.startAccessing(url)
                let values = try? url.resourceValues(forKeys: [.fileSizeKey])
                sizes[item.id] = Int64(values?.fileSize ?? 0)
                if accessing { bookmarks.stopAccessing(url) }
            }
        }
        let indexed = items.enumerated().map { (index: $0.offset, item: $0.element) }
        items = indexed.sorted { lhs, rhs in
            let leftMissing = status(for: lhs.item) == .missing
            let rightMissing = status(for: rhs.item) == .missing
            if leftMissing != rightMissing { return !leftMissing }
            let comparison: ComparisonResult
            switch key {
            case .name:
                comparison = lhs.item.displayName.localizedStandardCompare(rhs.item.displayName)
            case .dateAdded:
                comparison = lhs.item.addedAt == rhs.item.addedAt ? .orderedSame : (lhs.item.addedAt < rhs.item.addedAt ? .orderedAscending : .orderedDescending)
            case .kind:
                let left = lhs.item.isDirectory ? "" : URL(fileURLWithPath: lhs.item.lastKnownPath).pathExtension
                let right = rhs.item.isDirectory ? "" : URL(fileURLWithPath: rhs.item.lastKnownPath).pathExtension
                comparison = left.localizedStandardCompare(right)
            case .size:
                let left = sizes[lhs.item.id] ?? 0
                let right = sizes[rhs.item.id] ?? 0
                comparison = left == right ? .orderedSame : (left < right ? .orderedAscending : .orderedDescending)
            }
            if comparison == .orderedSame { return lhs.index < rhs.index }
            return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
        }.map(\.item)
        scheduleSave()
    }

    func status(for item: ShelfItem) -> Status {
        statuses[item.id] ?? .inaccessible
    }

    func refreshStatuses() {
        var changed = false
        var newStatuses: [UUID: Status] = [:]
        for index in items.indices {
            let item = items[index]
            do {
                let resolved = try bookmarks.resolve(item.bookmarkData)
                let url = resolved.url.standardizedFileURL
                let accessing = bookmarks.startAccessing(url)
                defer { if accessing { bookmarks.stopAccessing(url) } }
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
                    newStatuses[item.id] = .missing
                    continue
                }
                guard FileManager.default.isReadableFile(atPath: url.path) else {
                    newStatuses[item.id] = .inaccessible
                    continue
                }
                newStatuses[item.id] = .ok
                if item.lastKnownPath != url.path || item.displayName != url.lastPathComponent || item.isDirectory != isDirectory.boolValue {
                    items[index].lastKnownPath = url.path
                    items[index].displayName = url.lastPathComponent
                    items[index].isDirectory = isDirectory.boolValue
                    changed = true
                }
                if resolved.isStale, let data = try? bookmarks.create(for: url) {
                    items[index].bookmarkData = data
                    changed = true
                }
            } catch {
                newStatuses[item.id] = FileManager.default.fileExists(atPath: item.lastKnownPath) ? .inaccessible : .missing
            }
        }
        statuses = newStatuses
        if changed { scheduleSave() }
    }

    func relocate(id: UUID, to url: URL) throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let accessing = bookmarks.startAccessing(url)
        defer { if accessing { bookmarks.stopAccessing(url) } }
        let data = try bookmarks.create(for: url)
        var isDirectory: ObjCBool = false
        let path = url.standardizedFileURL.path
        _ = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        items[index].bookmarkData = data
        items[index].lastKnownPath = path
        items[index].displayName = url.lastPathComponent
        items[index].isDirectory = isDirectory.boolValue
        refreshStatuses()
        scheduleSave()
    }

    func save() throws {
        saveTask?.cancel()
        saveTask = nil
        do {
            try persistence.save(items)
            lastSaveError = nil
        } catch {
            lastSaveError = error
            throw error
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(300))
                try self?.save()
            } catch is CancellationError {
                return
            } catch {
                // save() exposes the error for the caller to handle.
            }
        }
    }
}
