import AppKit
import Observation

@MainActor
@Observable
final class ShelfDropState {
    var isTargeted = false
    private let store: ShelfStore?

    init(store: ShelfStore?) {
        self.store = store
    }

    func operation(for sender: any NSDraggingInfo) -> NSDragOperation {
        guard store != nil,
              sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) else {
            return []
        }
        if sender.draggingSourceOperationMask.contains(.copy) { return .copy }
        if sender.draggingSourceOperationMask.contains(.link) { return .link }
        return []
    }

    func accept(_ sender: any NSDraggingInfo) -> Bool {
        guard let store, !operation(for: sender).isEmpty,
              let objects = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) else {
            return false
        }
        let urls = objects.compactMap { $0 as? URL }.filter(\.isFileURL)
        guard !urls.isEmpty else { return false }
        do {
            try store.add(urls: urls)
            return true
        } catch {
            NSLog("DropShelf: failed to add dropped files: %@", String(describing: error))
            return false
        }
    }
}
