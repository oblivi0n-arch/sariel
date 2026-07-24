import SwiftUI

extension SettingsView {
    var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "circle.lefthalf.filled", title: L10n.Settings.appearanceSectionTitle) {
                EmptyView()
            }
            
            Toggle(isOn: $themeManager.followSystem) {
                Text(L10n.Settings.matchSystemAppearance)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textPrimary)
            }
            .toggleStyle(.switch)
            .tint(Theme.textPrimary)
            
            themeSwatchPicker
                .opacity(themeManager.followSystem ? 0.4 : 1)
                .disabled(themeManager.followSystem)
            
            Text(L10n.Settings.followSystemDescription)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
    }
    
    private var themeSwatchPicker: some View {
        HStack(spacing: 14) {
            themeSwatch(for: .dark, label: L10n.Settings.themeDark, fill: .black)
            themeSwatch(for: .light, label: L10n.Settings.themeLight, fill: .white)
        }
    }
    
    private func themeSwatch(for theme: AppTheme, label: String, fill: Color) -> some View {
        let isSelected = themeManager.current == theme
        
        return Button(action: { themeManager.current = theme }) {
            VStack(spacing: 6) {
                Circle()
                    .fill(fill)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle().stroke(
                            isSelected ? Color.red.opacity(0.8) : Theme.border,
                            lineWidth: isSelected ? 2 : 0.5
                        )
                    )
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(theme == .dark ? .white : .black)
                        }
                    }
                
                Text(label)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .buttonStyle(.plain)
    }
    
    var languageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "globe", title: L10n.Settings.languageSectionTitle) {
                EmptyView()
            }
            
            HStack(spacing: 10) {
                languageOption(.pl, label: "PL")
                languageOption(.en, label: "EN")
            }
        }
    }
    
    private func languageOption(_ language: AppLanguage, label: String) -> some View {
        let isSelected = languageManager.current == language
        
        return Button(action: { languageManager.current = language }) {
            Text(label)
                .font(Typography.label)
                .foregroundStyle(isSelected ? Theme.background : Theme.textPrimary)
                .frame(width: 52, height: 32)
                .background(isSelected ? Color.red.opacity(0.8) : Theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.clear : Theme.border, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}

extension L10n.Settings {
    static var languageSectionTitle: String {
        switch L10n.lang {
        case .en: return "LANGUAGE"
        case .pl: return "JĘZYK"
        }
    }
    
    static var appearanceSectionTitle: String {
        switch L10n.lang {
        case .en: return "APPEARANCE"
        case .pl: return "WYGLĄD"
        }
    }
    
    static var matchSystemAppearance: String {
        switch L10n.lang {
        case .en: return "Match system appearance"
        case .pl: return "Dopasuj do systemu"
        }
    }
    
    static var themeDark: String {
        switch L10n.lang {
        case .en: return "Dark"
        case .pl: return "Ciemny"
        }
    }
    
    static var themeLight: String {
        switch L10n.lang {
        case .en: return "Light"
        case .pl: return "Jasny"
        }
    }
    
    static var followSystemDescription: String {
        switch L10n.lang {
        case .en: return "When enabled, Sariel follows macOS's light/dark setting automatically and the choice above is ignored."
        case .pl: return "Po włączeniu tej opcji, Sariel automatycznie dostosowuje się do trybu jasny/ciemny systemu macOS, a wybór powyżej jest ignorowany."
        }
    }
}
