import SwiftUI

struct OnboardingView: View {
    let hotKey: HotKeyService
    let finish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    var body: some View {
        VStack(spacing: 16) {
            Group {
                switch page {
                case 0:
                    illustration("tray.full.fill")
                    Text("Welcome to DropShelf").font(.title2.bold())
                    Text("DropShelf keeps files at hand while you work. It only stores references — your original files are never copied, moved or deleted.")
                case 1:
                    HStack(spacing: 20) {
                        illustration("arrow.down.doc")
                        illustration("tray.full")
                        illustration("arrow.up.doc")
                    }
                    Text("Drop & drag").font(.title2.bold())
                    Text("Drag files or folders from Finder onto the shelf. Later, drag them from the shelf into Finder, Mail or any app.")
                case 2:
                    illustration("keyboard")
                    Text("Keyboard shortcuts").font(.title2.bold())
                    VStack(alignment: .leading, spacing: 5) {
                        shortcut(hotKey.display, "Show or hide the shelf")
                        shortcut(String(localized: "Space"), "Quick Look preview")
                        shortcut("⌘O", "Open")
                        shortcut("⌘R", "Reveal in Finder")
                        shortcut("⌫", "Remove from shelf")
                        shortcut("⌘A", "Select all")
                    }
                default:
                    illustration("lightbulb")
                    Text("A few tips").font(.title2.bold())
                    Text("Right-click empty shelf space to sort or clear it, or right-click an item for actions. Missing files show a warning and can be found again with Locate…. The menu bar icon gives you access to everything.")
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
            HStack {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index == page ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 7, height: 7)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Page \(page + 1) of 4"))
            HStack {
                Button("Back") { changePage(page - 1) }
                    .disabled(page == 0)
                Spacer()
                if page == 3 {
                    Button("Get Started", action: finish).keyboardShortcut(.defaultAction)
                } else {
                    Button("Next") { changePage(page + 1) }.keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(24)
        .frame(width: 460, height: 380)
    }

    private func illustration(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 36))
            .foregroundStyle(.tint)
            .accessibilityHidden(true)
    }

    private func shortcut(_ key: String, _ description: LocalizedStringKey) -> some View {
        HStack {
            Text(key).fontWeight(.medium).frame(width: 90, alignment: .trailing)
            Text(description)
        }
    }

    private func changePage(_ newPage: Int) {
        if reduceMotion { page = newPage }
        else { withAnimation(.easeInOut(duration: 0.2)) { page = newPage } }
    }
}
