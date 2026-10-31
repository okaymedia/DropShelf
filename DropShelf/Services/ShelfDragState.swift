import AppKit
import Observation

@MainActor
@Observable
final class ShelfDragState {
    private(set) var selectedIDs: Set<UUID> = []
    private var anchor: UUID?
    private let store: ShelfStore
    private let bookmarks = BookmarkService()
    private var accessedURLs: [URL] = []
    private var draggedIDs: Set<UUID> = []

    init(store: ShelfStore) {
        self.store = store
    }

    func select(_ id: UUID, modifiers: NSEvent.ModifierFlags) {
        let ids = store.items.map(\.id)
        guard let index = ids.firstIndex(of: id) else { return }
        if modifiers.contains(.shift), let anchor, let start = ids.firstIndex(of: anchor) {
            let range = min(start, index)...max(start, index)
            let rangeIDs = Set(ids[range])
            selectedIDs = modifiers.contains(.command) ? selectedIDs.union(rangeIDs) : rangeIDs
        } else if modifiers.contains(.command) {
            if selectedIDs.contains(id) { selectedIDs.remove(id) } else { selectedIDs.insert(id) }
            anchor = id
        } else {
            selectedIDs = [id]
            anchor = id
        }
    }

    func selectAll() {
        selectedIDs = Set(store.items.map(\.id))
        anchor = store.items.first?.id
    }

    func beginDrag() -> [(URL, NSImage)] {
        endDrag(operation: [])
        var result: [(URL, NSImage)] = []
        for item in store.items where selectedIDs.contains(item.id) {
            guard store.status(for: item) == .ok,
                  let resolved = try? bookmarks.resolve(item.bookmarkData), resolved.url.isFileURL else { continue }
            let url = resolved.url
            if bookmarks.startAccessing(url) { accessedURLs.append(url) }
            result.append((url, NSWorkspace.shared.icon(forFile: url.path)))
            draggedIDs.insert(item.id)
        }
        return result
    }

    func endDrag(operation: NSDragOperation) {
        for url in accessedURLs { bookmarks.stopAccessing(url) }
        accessedURLs.removeAll()
        if !operation.isEmpty && UserDefaults.standard.bool(forKey: "removeAfterDragOut") {
            store.remove(ids: draggedIDs)
            selectedIDs.subtract(draggedIDs)
        }
        draggedIDs.removeAll()
    }
}
