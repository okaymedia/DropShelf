import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class ShelfHostingView<Content: View>: NSHostingView<Content> {
    private let dropState: ShelfDropState

    init(rootView: Content, dropState: ShelfDropState) {
        self.dropState = dropState
        super.init(rootView: rootView)
        registerForDraggedTypes([NSPasteboard.PasteboardType(UTType.fileURL.identifier)])
    }

    @available(*, unavailable)
    required init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        let operation = dropState.operation(for: sender)
        dropState.isTargeted = !operation.isEmpty
        return operation
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        let operation = dropState.operation(for: sender)
        dropState.isTargeted = !operation.isEmpty
        return operation
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        dropState.isTargeted = false
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        dropState.isTargeted = false
        return dropState.accept(sender)
    }

    override func concludeDragOperation(_ sender: (any NSDraggingInfo)?) {
        dropState.isTargeted = false
    }
}
