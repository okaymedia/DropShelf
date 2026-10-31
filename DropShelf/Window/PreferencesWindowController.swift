import AppKit
import SwiftUI

@MainActor
final class PreferencesWindowController {
    private let window: NSWindow

    init(hotKey: HotKeyService, loginItem: LoginItemService, store: ShelfStore?, tipJar: TipJarService, openOnboarding: @escaping () -> Void) {
        let content = PreferencesView(hotKey: hotKey, loginItem: loginItem, store: store, tipJar: tipJar, openOnboarding: openOnboarding)
        window = NSWindow(contentViewController: NSHostingController(rootView: content))
        window.styleMask = [.titled, .closable]
        window.title = NSLocalizedString("DropShelf Preferences", comment: "Preferences window title")
        window.isReleasedWhenClosed = false
        window.center()
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
