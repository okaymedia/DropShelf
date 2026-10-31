import AppKit
import Quartz

@MainActor
final class ShelfPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    var quickLookService: QuickLookService?

    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool { true }
    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) { MainActor.assumeIsolated { quickLookService?.beginControl(panel) } }
    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) { MainActor.assumeIsolated { quickLookService?.endControl(panel) } }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 420),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        becomesKeyOnlyIfNeeded = true
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        minSize = NSSize(width: 200, height: 200)
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
    }
}
