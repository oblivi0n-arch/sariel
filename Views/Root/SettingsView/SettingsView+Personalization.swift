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
        HStack(alignment: .top, spacing: 14) {
            themeGroup(title: L10n.Settings.themeGroupOriginal) {
                themeSwatch(for: .dark, label: L10n.Settings.themeDark, fill: .black)
                themeSwatch(for: .light, label: L10n.Settings.themeLight, fill: .white, checkmarkColor: .black)
            }

            themeGroupDivider

            themeGroup(title: L10n.Settings.themeGroupCustom) {
                themeSwatch(for: .starlight, label: L10n.Settings.themeStarlight, fill: Color(hex: "05070D"))
                themeSwatch(for: .witness, label: L10n.Settings.themeWitness, fill: Color(hex: "14100A"))
                themeSwatch(for: .ash, label: L10n.Settings.themeAsh, fill: Color(hex: "0E0E12"))
                themeSwatch(for: .wildwood, label: L10n.Settings.themeWildwood, fill: Color(hex: "0A1210"))
                themeSwatch(for: .rust, label: L10n.Settings.themeRust, fill: Color(hex: "150A08"))
            }
        }
    }

    private func themeGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)

            HStack(spacing: 14) {
                content()
            }
        }
    }

    private var themeGroupDivider: some View {
        Rectangle()
            .fill(Theme.border)
            .frame(width: 1)
    }
    
    private func themeSwatch(
        for theme: AppTheme,
        label: String,
        fill: Color,
        checkmarkColor: Color = .white
    ) -> some View {
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
                                .foregroundStyle(checkmarkColor)
                        }
                    }
                    .hoverBorder(Circle())

                Text(label)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)
            }
            .contentShape(Rectangle())
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
            
            Text(L10n.Settings.languageSectionHint)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
    }
    
    private func languageOption(_ language: AppLanguage, label: String) -> some View {
        let isSelected = languageManager.current == language

        return Button(action: { languageManager.current = language }) {
            Text(label)
                .font(Typography.label)
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textMuted)
                .frame(width: 52, height: 32)
                .contentShape(Rectangle())
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Theme.borderStrong : Theme.border, lineWidth: isSelected ? 1 : 0.5)
                )
                .hoverBorder(cornerRadius: 8)
        }
        .buttonStyle(.plain)
    }
    
    var identitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "person", title: L10n.Settings.identitySectionTitle) {
                EmptyView()
            }
            
            PlaceholderTextField(placeholder: L10n.Settings.usernamePlaceholder, text: $draftUsername)
                .padding(10)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                .focused($isUsernameFieldFocused)
                .onSubmit { commitUsername() }
                .onChange(of: draftUsername) { _, newValue in
                    if newValue.count > AppLimits.maxUsernameLength {
                        draftUsername = String(newValue.prefix(AppLimits.maxUsernameLength))
                    }
                }
                .onChange(of: isUsernameFieldFocused) { wasFocused, isFocused in
                    if wasFocused && !isFocused {
                        commitUsername()
                    }
                }
            
            Text("\(draftUsername.count)/\(AppLimits.maxUsernameLength)")
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
    }
    
    var aboutMeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "text.quote", title: L10n.Settings.aboutMeSectionTitle) {
                EmptyView()
            }
            
            ZStack(alignment: .topLeading) {
                if aboutMe.isEmpty {
                    Text(L10n.Settings.aboutMePlaceholder)
                        .font(Theme.uiFont)
                        .foregroundStyle(Theme.textFaint)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $aboutMe)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 9)
                    .padding(.top, 10)
                    .padding(.bottom, 7)
                    .onChange(of: aboutMe) { _, newValue in
                        if newValue.count > AppLimits.maxAboutMeLength {
                            aboutMe = String(newValue.prefix(AppLimits.maxAboutMeLength))
                        }
                    }
            }
            .frame(height: 120)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
            
            Text("\(aboutMe.count)/\(AppLimits.maxAboutMeLength)")
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
            
            if hasStartedAcquaintance {
                Button(action: handleAcquaintanceLinkTap) {
                    Text(L10n.Settings.restartAcquaintanceLink)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
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
    
    static var themeGroupOriginal: String {
        switch L10n.lang {
        case .en: return "ORIGINAL"
        case .pl: return "ORIGINAL"
        }
    }

    static var themeGroupCustom: String {
        switch L10n.lang {
        case .en: return "CUSTOM"
        case .pl: return "CUSTOM"
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
    
    static var themeStarlight: String {
        switch L10n.lang {
        case .en: return "Starlight"
        case .pl: return "Starlight"
        }
    }
    
    static var themeWitness: String {
        switch L10n.lang {
        case .en: return "Testament"
        case .pl: return "Świadectwo"
        }
    }

    static var themeAsh: String {
        switch L10n.lang {
        case .en: return "Ash"
        case .pl: return "Popiół"
        }
    }

    static var themeWildwood: String {
        switch L10n.lang {
        case .en: return "Wildwood"
        case .pl: return "Knieja"
        }
    }

    static var themeRust: String {
        switch L10n.lang {
        case .en: return "Rust"
        case .pl: return "Rdza"
        }
    }
    
    static var followSystemDescription: String {
        switch L10n.lang {
        case .en: return "When enabled, Sariel follows macOS's light/dark setting automatically and the choice above is ignored."
        case .pl: return "Po włączeniu tej opcji, Sariel automatycznie dostosowuje się do trybu jasny/ciemny systemu macOS, a wybór powyżej jest ignorowany."
        }
    }
    
    static var identitySectionTitle: String {
        switch L10n.lang {
        case .en: return "IDENTITY"
        case .pl: return "TOŻSAMOŚĆ"
        }
    }
    
    static var usernamePlaceholder: String {
        switch L10n.lang {
        case .en: return "What should I call you?"
        case .pl: return "Jak mam się do Ciebie zwracać?"
        }
    }
    
    static var languageSectionHint: String {
        switch L10n.lang {
        case .en: return "Ollama tends to work best in English, regardless of what you pick here."
        case .pl: return "Ollama działa najlepiej po angielsku, niezależnie od wyboru powyżej."
        }
    }
    
    static var aboutMeSectionTitle: String {
        switch L10n.lang {
        case .en: return "ABOUT ME"
        case .pl: return "O MNIE"
        }
    }
    
    static var aboutMePlaceholder: String {
        switch L10n.lang {
        case .en: return "A few words about yourself, for Sariel to keep in mind..."
        case .pl: return "Kilka słów o Tobie, żeby Sariel je pamiętała..."
        }
    }
    
    static var restartAcquaintanceLink: String {
        switch L10n.lang {
        case .en: return "Have the acquaintance conversation again"
        case .pl: return "Przeprowadź ponownie rozmowę zapoznawczą"
        }
    }
}
