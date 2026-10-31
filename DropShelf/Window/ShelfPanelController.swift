import AppKit
import SwiftUI

@MainActor
final class ShelfPanelController {
    private let panel: ShelfPanel
    private let store: ShelfStore?
    private var hideTask: Task<Void, Never>?
    private var isShown = false
    private let fadeDuration: TimeInterval = 0.15

    init(store: ShelfStore?, openPreferences: @escaping @MainActor () -> Void) {
        let panel = ShelfPanel()
        self.panel = panel
        self.store = store
        let quickLook = QuickLookService()
        panel.quickLookService = quickLook

        let effectView = NSVisualEffectView()
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 12
        effectView.layer?.masksToBounds = true

        let dropState = ShelfDropState(store: store)
        let hostingView = ShelfHostingView(rootView: ShelfRootView(store: store, dropState: dropState, quickLook: quickLook, openPreferences: openPreferences), dropState: dropState)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        effectView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: effectView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor)
        ])
        panel.contentView = effectView

        let frameName = "ShelfPanel"
        if !panel.setFrameUsingName(frameName), let screen = NSScreen.main ?? NSScreen.screens.first {
            let visibleFrame = screen.visibleFrame
            let size = panel.frame.size
            panel.setFrameOrigin(NSPoint(x: visibleFrame.maxX - size.width - 24,
                                         y: visibleFrame.midY - size.height / 2))
        }
        panel.setFrameAutosaveName(frameName)
    }

    func show() {
        guard !isShown else { return }
        store?.refreshStatuses()
        hideTask?.cancel()
        hideTask = nil
        isShown = true
        if !panel.isVisible {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = self.fadeDuration
            self.panel.animator().alphaValue = 1
        }
    }

    func hide() {
        guard isShown else { return }
        isShown = false
        NSAnimationContext.runAnimationGroup { context in
            context.duration = self.fadeDuration
            self.panel.animator().alphaValue = 0
        }
        hideTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(150))
            } catch {
                return
            }
            self?.panel.orderOut(nil)
            self?.hideTask = nil
        }
    }

    func toggle() {
        if isShown { hide() } else { show() }
    }
}
