import AppKit
import Quartz

@MainActor
final class QuickLookService: NSObject, @preconcurrency QLPreviewPanelDataSource, @preconcurrency QLPreviewPanelDelegate {
    private let bookmarks = BookmarkService()
    private var urls: [URL] = []
    private var accessedURLs: [URL] = []

    func toggle(items: [ShelfItem]) {
        guard let panel = QLPreviewPanel.shared() else { return }
        if panel.isVisible {
            panel.orderOut(nil)
            return
        }
        releaseAccess()
        for item in items {
            guard let resolved = try? bookmarks.resolve(item.bookmarkData), resolved.url.isFileURL else { continue }
            if bookmarks.startAccessing(resolved.url) { accessedURLs.append(resolved.url) }
            urls.append(resolved.url)
        }
        guard !urls.isEmpty else { return }
        panel.makeKeyAndOrderFront(nil)
        panel.reloadData()
    }

    func beginControl(_ panel: QLPreviewPanel) {
        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
    }

    func endControl(_ panel: QLPreviewPanel) {
        panel.dataSource = nil
        panel.delegate = nil
        releaseAccess()
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int { urls.count }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        urls[index] as NSURL
    }

    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        guard event.type == .keyDown, event.keyCode == 49,
              event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty else { return false }
        panel.orderOut(nil)
        return true
    }

    private func releaseAccess() {
        for url in accessedURLs { bookmarks.stopAccessing(url) }
        accessedURLs.removeAll()
        urls.removeAll()
    }
}
