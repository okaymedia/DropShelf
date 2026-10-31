import AppKit

@MainActor
final class ShelfActionService {
    let store: ShelfStore
    let selection: ShelfDragState
    let quickLook: QuickLookService
    private let bookmarks = BookmarkService()

    init(store: ShelfStore, selection: ShelfDragState, quickLook: QuickLookService) {
        self.store = store
        self.selection = selection
        self.quickLook = quickLook
    }

    var selectedItems: [ShelfItem] { store.items.filter { selection.selectedIDs.contains($0.id) } }
    var availableItems: [ShelfItem] { selectedItems.filter { store.status(for: $0) == .ok } }
    var allAvailable: Bool { !selectedItems.isEmpty && availableItems.count == selectedItems.count }

    func open() {
        guard allAvailable else { return }
        withAccess(to: availableItems) { urls in
            for url in urls { NSWorkspace.shared.open(url) }
        }
    }

    func reveal() {
        guard allAvailable else { return }
        withAccess(to: availableItems) { NSWorkspace.shared.activateFileViewerSelecting($0) }
    }

    func preview() {
        guard allAvailable else { return }
        quickLook.toggle(items: availableItems)
    }

    func remove() { store.remove(ids: selection.selectedIDs) }

    func locate() {
        guard selectedItems.count == 1, let item = selectedItems.first, store.status(for: item) != .ok else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try store.relocate(id: item.id, to: url)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    func clear() {
        guard !store.items.isEmpty else { return }
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Clear Shelf?", comment: "")
        alert.informativeText = NSLocalizedString("This removes all items from the shelf. Original files are not affected.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Clear Shelf", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        if alert.runModal() == .alertFirstButtonReturn { store.clear() }
    }

    private func withAccess(to items: [ShelfItem], perform: ([URL]) -> Void) {
        var urls: [URL] = []
        var accessed: [URL] = []
        defer { for url in accessed { bookmarks.stopAccessing(url) } }
        for item in items {
            guard let resolved = try? bookmarks.resolve(item.bookmarkData), resolved.url.isFileURL else { continue }
            if bookmarks.startAccessing(resolved.url) { accessed.append(resolved.url) }
            urls.append(resolved.url)
        }
        if !urls.isEmpty { perform(urls) }
    }
}
