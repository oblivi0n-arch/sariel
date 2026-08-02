import SwiftUI

struct AppKeyboardShortcut: Equatable {
    var key: String
    var modifiers: Int

    var eventModifiers: EventModifiers {
        EventModifiers(rawValue: modifiers)
    }

    var keyEquivalent: KeyEquivalent {
        KeyEquivalent(Character(key))
    }

    var displayString: String {
        var s = ""
        let mods = eventModifiers
        if mods.contains(.control) { s += "⌃" }
        if mods.contains(.option)  { s += "⌥" }
        if mods.contains(.shift)   { s += "⇧" }
        if mods.contains(.command) { s += "⌘" }
        s += key.uppercased()
        return s
    }
}

extension AppKeyboardShortcut: RawRepresentable {
    init?(rawValue: String) {
        let parts = rawValue.split(separator: "|")
        guard parts.count == 2, let mod = Int(parts[1]), let key = parts.first else { return nil }
        self.key = String(key)
        self.modifiers = mod
    }

    var rawValue: String {
        "\(key)|\(modifiers)"
    }
}

enum ShortcutAction: String, CaseIterable {
    case dashboard, chat, journal, tribunal, meditation

    var storageKey: String { "shortcut.\(rawValue)" }

    var defaultShortcut: AppKeyboardShortcut {
        switch self {
        case .dashboard: return AppKeyboardShortcut(key: "1", modifiers: EventModifiers.command.rawValue)
        case .chat:      return AppKeyboardShortcut(key: "2", modifiers: EventModifiers.command.rawValue)
        case .journal:   return AppKeyboardShortcut(key: "3", modifiers: EventModifiers.command.rawValue)
        case .tribunal:  return AppKeyboardShortcut(key: "4", modifiers: EventModifiers.command.rawValue)
        case .meditation: return AppKeyboardShortcut(key: "5", modifiers: EventModifiers.command.rawValue)
        }
    }
}
