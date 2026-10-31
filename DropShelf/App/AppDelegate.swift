import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private(set) var shelfStore: ShelfStore?
    private var shelfPanelController: ShelfPanelController?
    private var preferencesWindowController: PreferencesWindowController?
    private var onboardingWindowController: OnboardingWindowController?
    private(set) var hotKeyService: HotKeyService?
    private(set) var loginItemService = LoginItemService()
    private let tipJarService = TipJarService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { await tipJarService.load() }
        do {
            shelfStore = try ShelfStore(persistence: PersistenceService())
        } catch {
            NSLog("DropShelf: failed to load shelf: %@", String(describing: error))
        }
        UserDefaults.standard.register(defaults: ["showShelfOnLaunch": true])
        let panelController = ShelfPanelController(store: shelfStore, openPreferences: { [weak self] in self?.openPreferences() })
        shelfPanelController = panelController
        if UserDefaults.standard.bool(forKey: "showShelfOnLaunch") {
            panelController.show()
        }

        let hotKey = HotKeyService { [weak self] in self?.toggleShelf() }
        hotKeyService = hotKey

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(named: "MenuBarIcon")
        item.button?.image?.isTemplate = true
        item.button?.setAccessibilityLabel("DropShelf")

        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: NSLocalizedString("Show/Hide Shelf", comment: ""), action: #selector(toggleShelf), keyEquivalent: "")
        toggleItem.title = "\(NSLocalizedString("Show/Hide Shelf", comment: ""))     \(hotKey.display)"
        hotKey.onChange = { [weak toggleItem] shortcut in
            toggleItem?.title = "\(NSLocalizedString("Show/Hide Shelf", comment: ""))     \(shortcut)"
        }
        toggleItem.target = self
        menu.addItem(toggleItem)
        let preferencesItem = NSMenuItem(title: NSLocalizedString("Preferences…", comment: ""), action: #selector(openPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        let supportItem = NSMenuItem(title: NSLocalizedString("Support DropShelf…", comment: ""), action: #selector(openPreferences), keyEquivalent: "")
        supportItem.target = self
        menu.addItem(supportItem)
        let onboardingItem = NSMenuItem(title: NSLocalizedString("How It Works…", comment: ""), action: #selector(openOnboarding), keyEquivalent: "")
        onboardingItem.target = self
        menu.addItem(onboardingItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item

        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            openOnboarding()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        do {
            try shelfStore?.save()
        } catch {
            NSLog("DropShelf: failed to save shelf: %@", String(describing: error))
        }
    }

    @objc private func toggleShelf() {
        shelfPanelController?.toggle()
    }

    @objc private func openOnboarding() {
        guard let hotKeyService else { return }
        if onboardingWindowController == nil {
            onboardingWindowController = OnboardingWindowController(hotKey: hotKeyService)
        }
        onboardingWindowController?.show()
    }

    @objc private func openPreferences() {
        guard let hotKeyService else { return }
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(hotKey: hotKeyService, loginItem: loginItemService, store: shelfStore, tipJar: tipJarService, openOnboarding: { [weak self] in self?.openOnboarding() })
        }
        preferencesWindowController?.show()
    }
}
