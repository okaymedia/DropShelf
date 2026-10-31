import AppKit
import Carbon
import Observation

@MainActor
@Observable
final class HotKeyService {
    private(set) var display: String
    private(set) var registrationFailed = false
    @ObservationIgnored private var hotKey: EventHotKeyRef?
    @ObservationIgnored private var handler: EventHandlerRef?
    @ObservationIgnored private let toggle: () -> Void
    @ObservationIgnored var onChange: ((String) -> Void)?

    init(toggle: @escaping () -> Void) {
        self.toggle = toggle
        let defaults = UserDefaults.standard
        let keyCode = defaults.object(forKey: "hotKeyCode") == nil ? UInt32(kVK_ANSI_D) : UInt32(defaults.integer(forKey: "hotKeyCode"))
        let modifiers = defaults.object(forKey: "hotKeyModifiers") == nil ? UInt32(optionKey | cmdKey) : UInt32(defaults.integer(forKey: "hotKeyModifiers"))
        let keyName = defaults.string(forKey: "hotKeyName") ?? "D"
        display = Self.label(keyName: keyName, modifiers: modifiers)
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var identifier = EventHotKeyID()
            let result = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, Int(MemoryLayout<EventHotKeyID>.size), nil, &identifier)
            guard result == noErr, identifier.signature == 0x44534846, identifier.id == 1 else { return OSStatus(eventNotHandledErr) }
            MainActor.assumeIsolated {
                Unmanaged<HotKeyService>.fromOpaque(context).takeUnretainedValue().toggle()
            }
            return noErr
        }, 1, &eventType, context, &handler)
        if status == noErr {
            registrationFailed = !register(keyCode: keyCode, modifiers: modifiers)
        } else {
            registrationFailed = true
        }
    }

    func setShortcut(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard !flags.intersection([.command, .option, .control]).isEmpty,
              let characters = event.charactersIgnoringModifiers, !characters.isEmpty,
              characters.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) else { return }
        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        let code = UInt32(event.keyCode)
        let defaults = UserDefaults.standard
        let oldCode = defaults.object(forKey: "hotKeyCode") == nil ? UInt32(kVK_ANSI_D) : UInt32(defaults.integer(forKey: "hotKeyCode"))
        let oldModifiers = defaults.object(forKey: "hotKeyModifiers") == nil ? UInt32(optionKey | cmdKey) : UInt32(defaults.integer(forKey: "hotKeyModifiers"))
        if code == oldCode && modifiers == oldModifiers && hotKey != nil { registrationFailed = false; return }
        if let hotKey { UnregisterEventHotKey(hotKey); self.hotKey = nil }
        guard handler != nil, register(keyCode: code, modifiers: modifiers) else {
            _ = register(keyCode: oldCode, modifiers: oldModifiers)
            registrationFailed = true
            return
        }
        let name = characters.uppercased()
        defaults.set(Int(code), forKey: "hotKeyCode")
        defaults.set(Int(modifiers), forKey: "hotKeyModifiers")
        defaults.set(name, forKey: "hotKeyName")
        display = Self.label(keyName: name, modifiers: modifiers)
        registrationFailed = false
        onChange?(display)
    }

    private func register(keyCode: UInt32, modifiers: UInt32) -> Bool {
        var reference: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, EventHotKeyID(signature: 0x44534846, id: 1), GetApplicationEventTarget(), 0, &reference)
        hotKey = reference
        return status == noErr
    }

    private static func label(keyName: String, modifiers: UInt32) -> String {
        var result = ""
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        return result + keyName
    }
}
