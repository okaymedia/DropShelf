import AppKit
import SwiftUI

@MainActor
private final class ShelfIconCache {
    static let shared = ShelfIconCache()
    private var icons: [String: NSImage] = [:]
    private var insertionOrder: [String] = []
    private let limit = 128

    func icon(for path: String) -> NSImage {
        if let icon = icons[path] { return icon }
        let icon = NSWorkspace.shared.icon(forFile: path)
        if insertionOrder.count == limit {
            icons.removeValue(forKey: insertionOrder.removeFirst())
        }
        icons[path] = icon
        insertionOrder.append(path)
        return icon
    }
}

struct ShelfRootView: View {
    let store: ShelfStore?
    let dropState: ShelfDropState
    let openPreferences: @MainActor () -> Void
    @State private var dragState: ShelfDragState?
    @State private var actions: ShelfActionService?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(store: ShelfStore?, dropState: ShelfDropState, quickLook: QuickLookService, openPreferences: @escaping @MainActor () -> Void) {
        self.store = store
        self.dropState = dropState
        self.openPreferences = openPreferences
        let selection = store.map { ShelfDragState(store: $0) }
        _dragState = State(initialValue: selection)
        _actions = State(initialValue: store.flatMap { store in selection.map { ShelfActionService(store: store, selection: $0, quickLook: quickLook) } })
    }

    var body: some View {
        VStack(spacing: 0) {
          Group {
            if let store, !store.items.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(store.items) { item in
                            HStack(spacing: 8) {
                                Image(nsImage: ShelfIconCache.shared.icon(for: item.lastKnownPath))
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                Text(item.displayName)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer(minLength: 0)
                                if store.status(for: item) != .ok {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .help(store.status(for: item) == .missing ? Text("Missing") : Text("Inaccessible"))
                                }
                            }
                            .help("Space: Quick Look")
                            .transition(.opacity)
                            .opacity(store.status(for: item) == .ok ? 1 : 0.5)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(dragState?.selectedIDs.contains(item.id) == true ? Color.accentColor.opacity(0.3) : .clear)
                            .overlay {
                                if let dragState, let actions { ShelfDragView(itemID: item.id, state: dragState, actions: actions).accessibilityHidden(true) }
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(Text(item.displayName))
                            .accessibilityValue(statusText(store.status(for: item)))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .transition(.opacity)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.system(size: 32))
                    Text("Drop files here")
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          Divider()
          Text(countText(store?.items.count ?? 0))
              .font(.caption)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .trailing)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
        }
        .contextMenu {
            Menu("Sort by") {
                sortButton("Name", key: .name)
                sortButton("Date Added", key: .dateAdded)
                sortButton("Kind", key: .kind)
                sortButton("Size", key: .size)
                Divider()
                Button {
                    if let store { store.sort(by: store.sortKey, ascending: true) }
                } label: {
                    if store?.sortAscending != false { Label("Ascending", systemImage: "checkmark") }
                    else { Text("Ascending") }
                }
                Button {
                    if let store { store.sort(by: store.sortKey, ascending: false) }
                } label: {
                    if store?.sortAscending == false { Label("Descending", systemImage: "checkmark") }
                    else { Text("Descending") }
                }
            }
            .disabled(store == nil)
            Button("Clear Shelf…") { actions?.clear() }
                .disabled(store?.items.isEmpty != false)
            Button("Select All") { dragState?.selectAll() }
                .keyboardShortcut("a", modifiers: .command)
                .disabled(store?.items.isEmpty != false)
            Divider()
            Text("Quick Look: select an item and press Space")
            Button("Preferences…") { openPreferences() }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: store?.items.map(\.id) ?? [])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(dropState.isTargeted ? Color.accentColor : .clear, lineWidth: 3)
                .padding(4)
                .allowsHitTesting(false)
        }
    }

    private func sortButton(_ title: LocalizedStringKey, key: ShelfStore.SortKey) -> some View {
        Button {
            if let store { store.sort(by: key, ascending: store.sortAscending) }
        } label: {
            if store?.sortKey == key { Label(title, systemImage: "checkmark") }
            else { Text(title) }
        }
    }

    private func statusText(_ status: ShelfStore.Status) -> Text {
        switch status {
        case .ok: Text("Available")
        case .missing: Text("Missing")
        case .inaccessible: Text("Inaccessible")
        }
    }

    private func countText(_ count: Int) -> String {
        let format = count == 1 ? NSLocalizedString("%lld item", comment: "Shelf item count") : NSLocalizedString("%lld items", comment: "Shelf item count")
        return String(format: format, Int64(count))
    }

}
