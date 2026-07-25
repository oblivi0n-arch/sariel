import SwiftUI

extension SettingsView {
    var keyboardShortcutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "keyboard", title: L10n.Settings.shortcutsSectionTitle) {
                EmptyView()
            }

            VStack(alignment: .leading, spacing: 8) {
                shortcutRow(label: L10n.Sections.dashboard, shortcut: $dashboardShortcut)
                shortcutRow(label: L10n.Sections.chat, shortcut: $chatShortcut)
                shortcutRow(label: L10n.Sections.journal, shortcut: $journalShortcut)
                shortcutRow(label: L10n.Sections.tribunal, shortcut: $tribunalShortcut)
            }
        }
    }

    private func shortcutRow(label: String, shortcut: Binding<AppKeyboardShortcut>) -> some View {
        HStack {
            Text(label)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            ShortcutRecorderButton(shortcut: shortcut)
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
}
