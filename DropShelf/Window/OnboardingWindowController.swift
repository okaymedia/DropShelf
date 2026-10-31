import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    private let window: NSWindow

    init(hotKey: HotKeyService) {
        window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        super.init()
        window.contentViewController = NSHostingController(rootView: OnboardingView(hotKey: hotKey, finish: { [weak self] in
            self?.window.close()
        }))
        window.title = NSLocalizedString("How DropShelf Works", comment: "Onboarding window title")
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
    }
}
