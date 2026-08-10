import SwiftUI

extension SettingsView {
    var keyboardShortcutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "keyboard", title: L10n.Settings.shortcutsSectionTitle) {
                EmptyView()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                shortcutRow(action: .dashboard, label: L10n.Sections.dashboard, shortcut: $dashboardShortcut)
                shortcutRow(action: .chat, label: L10n.Sections.chat, shortcut: $chatShortcut)
                shortcutRow(action: .journal, label: L10n.Sections.journal, shortcut: $journalShortcut)
                shortcutRow(action: .tribunal, label: L10n.Sections.tribunal, shortcut: $tribunalShortcut)
                shortcutRow(action: .meditation, label: L10n.Sections.meditation, shortcut: $meditationShortcut)
            }
        }
    }
    
    private var assignedShortcuts: [(action: ShortcutAction, value: AppKeyboardShortcut)] {
        [
            (.dashboard, dashboardShortcut),
            (.chat, chatShortcut),
            (.journal, journalShortcut),
            (.tribunal, tribunalShortcut),
            (.meditation, meditationShortcut)
        ]
    }
    
    private func shortcutRow(action: ShortcutAction, label: String, shortcut: Binding<AppKeyboardShortcut>) -> some View {
        HStack {
            Text(label)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)
            
            Spacer()
            
            ShortcutRecorderButton(shortcut: shortcut) { candidate in
                assignedShortcuts.contains { $0.action != action && $0.value == candidate }
            }
        }
    }
}

extension L10n.Settings {
    static var shortcutsSectionTitle: String {
        switch L10n.lang {
        case .en: return "KEYBOARD SHORTCUTS"
        case .pl: return "SKRÓTY KLAWISZOWE"
        }
    }
    
    static var shortcutRecording: String {
        switch L10n.lang {
        case .en: return "press keys…"
        case .pl: return "wciśnij klawisze…"
        }
    }
    
    static var shortcutConflict: String {
        switch L10n.lang {
        case .en: return "already used"
        case .pl: return "już zajęty"
        }
    }
}
