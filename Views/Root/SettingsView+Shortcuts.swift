import SwiftUI

extension SettingsView {
    var keyboardShortcutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "keyboard", title: L10n.Settings.shortcutsSectionTitle) {
                EmptyView()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                shortcutRow(keys: "⌘1", label: L10n.Sections.dashboard)
                shortcutRow(keys: "⌘2", label: L10n.Sections.chat)
                shortcutRow(keys: "⌘3", label: L10n.Sections.journal)
                shortcutRow(keys: "⌘4", label: L10n.Sections.tribunal)
            }
        }
    }
    
    private func shortcutRow(keys: String, label: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)
            
            Spacer()
            
            Text(keys)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.border, lineWidth: 0.5))
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
}
