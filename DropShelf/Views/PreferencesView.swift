import AppKit
import SwiftUI

struct PreferencesView: View {
    let hotKey: HotKeyService
    let loginItem: LoginItemService
    let store: ShelfStore?
    let tipJar: TipJarService
    let openOnboarding: () -> Void
    @AppStorage("showShelfOnLaunch") private var showOnLaunch = true
    @AppStorage("removeAfterDragOut") private var removeAfterDrag = false
    @State private var confirmClear = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Form {
            LabeledContent("Global shortcut") {
                ShortcutRecorder(hotKey: hotKey)
                    .frame(width: 160, height: 24)
            }
            if hotKey.registrationFailed {
                Text("Shortcut unavailable. Choose another shortcut.").foregroundStyle(.red)
            }
            Toggle("Launch at login", isOn: Binding(get: { loginItem.isEnabled }, set: { loginItem.setEnabled($0) }))
            if loginItem.needsApproval {
                Text("Allow DropShelf in Login Items in System Settings.")
            }
            if loginItem.hasError {
                Text("Could not update the login item.").foregroundStyle(.red)
            }
            Toggle("Show shelf on launch", isOn: $showOnLaunch)
            Toggle("Remove after drag out", isOn: $removeAfterDrag)
            Button("How DropShelf Works…", action: openOnboarding)
            Button("Clear Shelf") { confirmClear = true }
                .disabled(store == nil || store?.items.isEmpty == true)
            TipJarView(tipJar: tipJar)
        }
        .padding(20)
        .frame(width: 430)
        .onAppear { loginItem.refresh() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { loginItem.refresh() } }
        .alert("Clear Shelf?", isPresented: $confirmClear) {
            Button("Cancel", role: .cancel) { }
            Button("Clear Shelf", role: .destructive) { store?.clear() }
        } message: {
            Text("This removes all items from the shelf. Original files are not affected.")
        }
    }
}

private struct ShortcutRecorder: NSViewRepresentable {
    let hotKey: HotKeyService

    func makeNSView(context: Context) -> RecorderView { RecorderView(hotKey: hotKey) }
    func updateNSView(_ view: RecorderView, context: Context) { view.stringValue = hotKey.display }

    @MainActor
    final class RecorderView: NSTextField {
        private let hotKey: HotKeyService
        init(hotKey: HotKeyService) {
            self.hotKey = hotKey
            super.init(frame: .zero)
            isEditable = false
            isSelectable = false
            alignment = .center
            stringValue = hotKey.display
            toolTip = NSLocalizedString("Click and press a shortcut", comment: "")
            setAccessibilityLabel(NSLocalizedString("Global shortcut", comment: ""))
            setAccessibilityHelp(NSLocalizedString("Click and press a shortcut", comment: ""))
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override var acceptsFirstResponder: Bool { true }
        override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self) }
        override func keyDown(with event: NSEvent) { hotKey.setShortcut(event: event) }
        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            guard window?.firstResponder === self else { return false }
            hotKey.setShortcut(event: event)
            return true
        }
    }
}
