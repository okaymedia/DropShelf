import AppKit
import SwiftUI

struct ShelfDragView: NSViewRepresentable {
    let itemID: UUID
    let state: ShelfDragState
    let actions: ShelfActionService

    func makeNSView(context: Context) -> DragView {
        DragView(itemID: itemID, state: state, actions: actions)
    }

    func updateNSView(_ view: DragView, context: Context) {
        view.itemID = itemID
        view.state = state
        view.actions = actions
    }

    @MainActor
    final class DragView: NSView, NSDraggingSource {
        var itemID: UUID
        var state: ShelfDragState
        var actions: ShelfActionService
        private var mouseDownPoint: NSPoint?
        private var pendingSelection = false
        private var dragging = false

        init(itemID: UUID, state: ShelfDragState, actions: ShelfActionService) {
            self.itemID = itemID
            self.state = state
            self.actions = actions
            super.init(frame: .zero)
            toolTip = NSLocalizedString("Space: Quick Look", comment: "")
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override var acceptsFirstResponder: Bool { true }

        override func mouseDown(with event: NSEvent) {
            window?.makeKey()
            window?.makeFirstResponder(self)
            mouseDownPoint = event.locationInWindow
            dragging = false
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            pendingSelection = state.selectedIDs.contains(itemID) && !modifiers.contains(.command) && !modifiers.contains(.shift)
            if !pendingSelection { state.select(itemID, modifiers: modifiers) }
        }

        override func mouseUp(with event: NSEvent) {
            if pendingSelection && !dragging { state.select(itemID, modifiers: []) }
            if event.clickCount == 2 && !dragging { actions.open() }
            pendingSelection = false
            mouseDownPoint = nil
        }

        override func mouseDragged(with event: NSEvent) {
            guard !dragging, let start = mouseDownPoint,
                  hypot(event.locationInWindow.x - start.x, event.locationInWindow.y - start.y) >= 3 else { return }
            let files = state.beginDrag()
            guard !files.isEmpty else { return }
            dragging = true
            let origin = convert(start, from: nil)
            let items = files.map { url, icon in
                let item = NSDraggingItem(pasteboardWriter: url as NSURL)
                item.setDraggingFrame(NSRect(x: origin.x - 16, y: origin.y - 16, width: 32, height: 32), contents: icon)
                return item
            }
            beginDraggingSession(with: items, event: event, source: self)
        }

        override func menu(for event: NSEvent) -> NSMenu? {
            window?.makeKey()
            window?.makeFirstResponder(self)
            if !state.selectedIDs.contains(itemID) { state.select(itemID, modifiers: []) }
            let menu = NSMenu()
            addMenuItem("Open", action: #selector(openItems), key: "o", enabled: actions.allAvailable, to: menu)
            addMenuItem("Reveal in Finder", action: #selector(revealItems), key: "r", enabled: actions.allAvailable, to: menu)
            addMenuItem("Quick Look", action: #selector(previewItems), key: "", enabled: actions.allAvailable, to: menu)
            let canLocate = actions.selectedItems.count == 1 && !actions.allAvailable
            addMenuItem("Locate…", action: #selector(locateItem), key: "", enabled: canLocate, to: menu)
            menu.addItem(.separator())
            addMenuItem("Remove from Shelf", action: #selector(removeItems), key: "", enabled: !actions.selectedItems.isEmpty, to: menu)
            addMenuItem("Clear Shelf", action: #selector(clearShelf), key: "", enabled: !actions.store.items.isEmpty, to: menu)
            return menu
        }

        private func addMenuItem(_ title: String, action: Selector, key: String, enabled: Bool, to menu: NSMenu) {
            let item = NSMenuItem(title: NSLocalizedString(title, comment: ""), action: action, keyEquivalent: key)
            item.target = self
            item.isEnabled = enabled
            menu.addItem(item)
            menu.autoenablesItems = false
        }

        @objc private func openItems() { actions.open() }
        @objc private func revealItems() { actions.reveal() }
        @objc private func previewItems() { actions.preview() }
        @objc private func locateItem() { actions.locate() }
        @objc private func removeItems() { actions.remove() }
        @objc private func clearShelf() { actions.clear() }

        override func keyDown(with event: NSEvent) {
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if modifiers.isEmpty {
                switch event.keyCode {
                case 49: actions.preview(); return
                case 51, 117: actions.remove(); return
                default: break
                }
            }
            super.keyDown(with: event)
        }

        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
               event.charactersIgnoringModifiers?.lowercased() == "a" {
                state.selectAll()
                return true
            }
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {
                switch event.charactersIgnoringModifiers?.lowercased() {
                case "o": actions.open(); return true
                case "r": actions.reveal(); return true
                default: break
                }
            }
            return super.performKeyEquivalent(with: event)
        }

        func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
            [.copy, .link, .generic]
        }

        func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
            state.endDrag(operation: operation)
            dragging = false
        }
    }
}
