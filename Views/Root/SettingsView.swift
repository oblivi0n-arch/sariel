import SwiftUI
import SwiftData
import AppKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var connectionMonitor: ConnectionMonitor
    @Binding var isPresented: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("isPostReset") private var isPostReset: Bool = false
    @AppStorage("ollamaHost") private var host: String = OllamaDefaults.host
    @AppStorage("ollamaModel") private var model: String = OllamaDefaults.model
    @AppStorage("useJournalContext") private var useJournalContext: Bool = false
    @AppStorage("useCredibilityContext") private var useCredibilityContext: Bool = false
    @AppStorage("autoStartOllama") private var autoStartOllama: Bool = false

    @State private var availableModels: [String] = []
    @State private var isLoadingModels = false
    @State private var modelsLoadError: String?
    @State private var showResetConfirmation = false
    
    private var credibilitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "scalemass", title: L10n.Settings.credibilitySectionTitle) {
                EmptyView()
            }

            Toggle(isOn: $useCredibilityContext) {
                Text(L10n.Settings.credibilityToggleLabel)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textPrimary)
            }
            .toggleStyle(.switch)
            .tint(Theme.textPrimary)

            Text(L10n.Settings.credibilityDescription(minimum: Commitment.credibilitySampleMinimum))
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
    }
    
    private var languageSection: some View {
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

    private var isHostValid: Bool {
        guard let url = URL(string: host), let scheme = url.scheme else { return false }
        return (scheme == "http" || scheme == "https") && url.host != nil
    }

    private struct OllamaTagsResponse: Codable {
        let models: [OllamaModelInfo]
    }

    private struct OllamaModelInfo: Codable {
        let name: String
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    appearanceSection
                    languageSection
                    keyboardShortcutsSection
                    ollamaSection
                    contextSection
                    credibilitySection
                    dangerZone
                    debugOnboardingSection //DEBUG ONLY
                }
                .padding(20)
            }
        }
        .background(Theme.background)
        .task {
            await fetchAvailableModels()
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .font(Typography.icon)
                .foregroundStyle(Theme.textMuted)

            Text(L10n.Settings.title)
                .font(Typography.title)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(Typography.iconButton)
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 24, height: 24)
                    .background(Theme.fieldBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.border).frame(height: 0.5)
        }
    }

    private var ollamaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "network", title: L10n.Settings.ollamaSectionTitle) {
                connectionBadge
            }
            
            Toggle(isOn: $autoStartOllama) {
                Text(L10n.Settings.autoStartOllamaLabel)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textPrimary)
            }
            .toggleStyle(.switch)
            .tint(Theme.textPrimary)

            Text(L10n.Settings.autoStartOllamaDescription)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)

            labeledField(
                title: L10n.Settings.hostFieldLabel,
                text: $host,
                isValid: host.isEmpty || isHostValid,
                errorMessage: L10n.Settings.hostFieldError
            )
            modelPicker
        }
    }

    private var connectionBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(connectionMonitor.isConnected ? Theme.textPrimary : Theme.textFaint)
                .frame(width: 6, height: 6)
            Text(connectionMonitor.isConnected ? L10n.Settings.connectedStatus : L10n.Settings.offlineStatus)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
    }

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "book.closed", title: L10n.Settings.journalSectionTitle) {
                EmptyView()
            }

            Toggle(isOn: $useJournalContext) {
                Text(L10n.Settings.journalContextToggleLabel)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textPrimary)
            }
            .toggleStyle(.switch)
            .tint(Theme.textPrimary)

            Text(L10n.Settings.journalContextDescription(count: PromptBuilder.journalContextEntryCount))
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "exclamationmark.triangle", title: L10n.Settings.dangerZoneTitle) {
                EmptyView()
            }

            Button(action: { showResetConfirmation = true }) {
                Text(L10n.Settings.resetButton)
                    .font(Typography.label)
                    .foregroundStyle(Color.red.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.4), lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            Text(L10n.Settings.resetDescription)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
        .confirmationDialog(
            L10n.Settings.resetConfirmTitle,
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Settings.resetConfirmButton, role: .destructive) {
                resetEverything()
            }
            Button(L10n.Settings.cancelButton, role: .cancel) {}
        } message: {
            Text(L10n.Settings.resetConfirmMessage)
        }
    }

    private func sectionHeader<Accessory: View>(
        icon: String,
        title: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(Typography.caption)
            }
            .foregroundStyle(Theme.textFaint)

            Spacer()

            accessory()
        }
    }

    private func labeledField(title: String, text: Binding<String>, isValid: Bool = true, errorMessage: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Typography.label)
                .foregroundStyle(Theme.textMuted)

            TextField(title, text: text)
                .textFieldStyle(.plain)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isValid ? Theme.border : Color.red.opacity(0.6), lineWidth: isValid ? 0.5 : 1)
                )

            if !isValid, let errorMessage {
                Text(errorMessage)
                    .font(Typography.caption)
                    .foregroundStyle(Color.red.opacity(0.8))
            }
        }
    }

    private var modelPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(L10n.Settings.modelFieldLabel)
                    .font(Typography.label)
                    .foregroundStyle(Theme.textMuted)
                
                Spacer()
                
                Button(action: { Task { await fetchAvailableModels() } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                        Text(isLoadingModels ? L10n.Settings.loadModelsButtonLoading : L10n.Settings.loadModelsButtonIdle)
                    }
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
                .disabled(isLoadingModels)
            }
            
            if isLoadingModels {
                Text(L10n.Settings.loadingModelsText)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
            } else if let modelsLoadError {
                Text(modelsLoadError)
                    .font(Typography.caption)
                    .foregroundStyle(Color.red.opacity(0.8))
            } else if availableModels.isEmpty {
                Text(L10n.Settings.noModelsFound)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
            } else {
                Picker("", selection: $model) {
                    ForEach(availableModels, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.textPrimary)
            }
            
            Text(L10n.Settings.modelRecommendationText)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
                .padding(.top, 2)
        }
    }

    private func resetEverything(skipOnboarding: Bool = false) {
        deleteAll(JournalEntry.self)
        deleteAll(JournalEntryTag.self)
        deleteAll(Conversation.self)
        deleteAll(Commitment.self)

        try? modelContext.save()

        hasCompletedOnboarding = skipOnboarding
        isPostReset = !skipOnboarding

        host = OllamaDefaults.host
        model = OllamaDefaults.model
        useJournalContext = false

        relaunchApp()
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) {
        guard let objects = try? modelContext.fetch(FetchDescriptor<T>()) else { return }
        for object in objects {
            modelContext.delete(object)
        }
    }

    private func relaunchApp() {
        let url = Bundle.main.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true

        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, _ in
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }

    private func fetchAvailableModels() async {
        guard isHostValid, let url = URL(string: "\(host)/api/tags") else {
            modelsLoadError = L10n.Settings.modelsLoadErrorHostInvalid
            return
        }

        isLoadingModels = true
        modelsLoadError = nil

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
            availableModels = decoded.models.map { $0.name }
        } catch {
            modelsLoadError = L10n.Settings.modelsLoadErrorGeneric
            availableModels = []
        }

        isLoadingModels = false
    }
    
    private var appearanceSection: some View {
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
    
    private var keyboardShortcutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "keyboard", title: L10n.Settings.shortcutsSectionTitle) {
                EmptyView()
            }

            VStack(alignment: .leading, spacing: 8) {
                shortcutRow(keys: "⌘1", label: L10n.Sections.chat)
                shortcutRow(keys: "⌘2", label: L10n.Sections.journal)
                shortcutRow(keys: "⌘3", label: L10n.Sections.tribunal)
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
    
    // MARK: DEBUG ONLY
    private var debugOnboardingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "ladybug", title: "DEBUG") {
                EmptyView()
            }

            HStack(spacing: 10) {
                Button("Force onboarding") {
                    isPostReset = false
                    hasCompletedOnboarding = false
                }
                Button("Force onboarding (post-reset)") {
                    isPostReset = true
                    hasCompletedOnboarding = false
                }
            }
            .font(Typography.caption)
            .buttonStyle(.plain)
            .foregroundStyle(Theme.textMuted)

            Button("Backdate pending commitments (unlock Tribunal)") {
                backdatePendingCommitments()
            }
            .font(Typography.caption)
            .buttonStyle(.plain)
            .foregroundStyle(Theme.textMuted)
            
            Button("Reset data (skip onboarding)") {
                resetEverything(skipOnboarding: true)
            }
            .font(Typography.caption)
            .buttonStyle(.plain)
            .foregroundStyle(Theme.textMuted)
        }
    }
    
    // MARK: DEBUG ONLY
    private func backdatePendingCommitments() {
        let descriptor = FetchDescriptor<Commitment>(
            predicate: #Predicate<Commitment> { $0.status == "pending" }
        )
        guard let pending = try? modelContext.fetch(descriptor) else { return }
        for commitment in pending {
            commitment.createdAt = Date().addingTimeInterval(-8 * 24 * 60 * 60)
        }
        try? modelContext.save()
    }
}

extension L10n {
    enum Settings {
        static var title: String {
            switch lang {
            case .en: return "settings"
            case .pl: return "ustawienia"
            }
        }
        
        static var languageSectionTitle: String {
            switch lang {
            case .en: return "LANGUAGE"
            case .pl: return "JĘZYK"
            }
        }

        static var appearanceSectionTitle: String {
            switch lang {
            case .en: return "APPEARANCE"
            case .pl: return "WYGLĄD"
            }
        }

        static var matchSystemAppearance: String {
            switch lang {
            case .en: return "Match system appearance"
            case .pl: return "Dopasuj do systemu"
            }
        }

        static var themeDark: String {
            switch lang {
            case .en: return "Dark"
            case .pl: return "Ciemny"
            }
        }

        static var themeLight: String {
            switch lang {
            case .en: return "Light"
            case .pl: return "Jasny"
            }
        }

        static var followSystemDescription: String {
            switch lang {
            case .en: return "When enabled, Sariel follows macOS's light/dark setting automatically and the choice above is ignored."
            case .pl: return "Po włączeniu tej opcji, Sariel automatycznie dostosowuje się do trybu jasny/ciemny systemu macOS, a wybór powyżej jest ignorowany."
            }
        }

        static var ollamaSectionTitle: String {
            switch lang {
            case .en: return "OLLAMA CLIENT"
            case .pl: return "KLIENT OLLAMA"
            }
        }

        static var connectedStatus: String {
            switch lang {
            case .en: return "connected"
            case .pl: return "połączono"
            }
        }

        static var offlineStatus: String {
            switch lang {
            case .en: return "offline"
            case .pl: return "offline"
            }
        }

        static var hostFieldLabel: String {
            switch lang {
            case .en: return "Host"
            case .pl: return "Host"
            }
        }

        static var hostFieldError: String {
            switch lang {
            case .en: return "Enter a valid URL, e.g. http://localhost:11434"
            case .pl: return "Podaj prawidłowy adres URL, np. http://localhost:11434"
            }
        }

        static var modelFieldLabel: String {
            switch lang {
            case .en: return "Model"
            case .pl: return "Model"
            }
        }

        static var loadModelsButtonLoading: String {
            switch lang {
            case .en: return "loading..."
            case .pl: return "ładowanie..."
            }
        }

        static var loadModelsButtonIdle: String {
            switch lang {
            case .en: return "load models"
            case .pl: return "wczytaj modele"
            }
        }

        static var loadingModelsText: String {
            switch lang {
            case .en: return "Loading models..."
            case .pl: return "Wczytywanie modeli..."
            }
        }

        static var modelsLoadErrorGeneric: String {
            switch lang {
            case .en: return "Could not load models. Is Ollama running?"
            case .pl: return "Nie udało się wczytać modeli. Czy Ollama jest uruchomiona?"
            }
        }

        static var modelsLoadErrorHostInvalid: String {
            switch lang {
            case .en: return "Fix the host URL first"
            case .pl: return "Najpierw popraw adres hosta"
            }
        }

        static var noModelsFound: String {
            switch lang {
            case .en: return "No models found"
            case .pl: return "Nie znaleziono modeli"
            }
        }

        static var modelRecommendationText: String {
            switch lang {
            case .en: return "Recommended: gemma4:e4b — natively supports system-role instructions, which this app relies on heavily (personality prompt, journal context, conversation summary). Smaller or older models may struggle with memory and long context."
            case .pl: return "Zalecany: gemma4:e4b — natywnie wspiera instrukcje typu system-role, na których ta aplikacja mocno się opiera (prompt osobowości, kontekst dziennika, podsumowanie rozmowy). Mniejsze lub starsze modele mogą mieć problemy z pamięcią i długim kontekstem."
            }
        }

        static var journalSectionTitle: String {
            switch lang {
            case .en: return "JOURNAL CONTEXT"
            case .pl: return "KONTEKST DZIENNIKA"
            }
        }

        static var journalContextToggleLabel: String {
            switch lang {
            case .en: return "Let Sariel read your recent journal entries"
            case .pl: return "Pozwól Sarielowi czytać Twoje ostatnie wpisy w dzienniku"
            }
        }

        static func journalContextDescription(count: Int) -> String {
            switch lang {
            case .en: return "When enabled, your last \(count) journal entries are sent as context in every conversation, so Sariel can notice patterns over time. Entries never leave your device."
            case .pl: return "Po włączeniu tej opcji, Twoje ostatnie \(count) wpisy w dzienniku są wysyłane jako kontekst w każdej rozmowie, dzięki czemu Sariel może zauważać powtarzające się wzorce. Wpisy nigdy nie opuszczają Twojego urządzenia."
            }
        }

        static var credibilitySectionTitle: String {
            switch lang {
            case .en: return "CREDIBILITY CONTEXT"
            case .pl: return "KONTEKST WIARYGODNOŚCI"
            }
        }

        static var credibilityToggleLabel: String {
            switch lang {
            case .en: return "Let Sariel factor in your track record on declarations"
            case .pl: return "Pozwól Sarielowi uwzględniać Twoją historię dotrzymywania deklaracji"
            }
        }

        static func credibilityDescription(minimum: Int) -> String {
            switch lang {
            case .en: return "When enabled, Sariel sees which of your declared commitments were fulfilled or broken from past Tribunal sessions, and adjusts its tone toward you accordingly. Requires at least \(minimum) resolved declarations."
            case .pl: return "Po włączeniu tej opcji, Sariel widzi które z Twoich zadeklarowanych zobowiązań zostały spełnione lub złamane podczas poprzednich sesji Trybunału, i dostosowuje do tego swój ton. Wymaga co najmniej \(minimum) rozstrzygniętych deklaracji."
            }
        }

        static var dangerZoneTitle: String {
            switch lang {
            case .en: return "DANGER ZONE"
            case .pl: return "STREFA NIEBEZPIECZEŃSTWA"
            }
        }

        static var resetButton: String {
            switch lang {
            case .en: return "RESET"
            case .pl: return "RESETUJ"
            }
        }

        static var resetDescription: String {
            switch lang {
            case .en: return "This option resets everything, including all conversations, journal entries, and your Ollama settings. The app will restart. This cannot be undone."
            case .pl: return "Ta opcja resetuje wszystko, w tym wszystkie rozmowy, wpisy w dzienniku i ustawienia Ollama. Aplikacja zostanie zrestartowana. Tej operacji nie da się cofnąć."
            }
        }

        static var resetConfirmTitle: String {
            switch lang {
            case .en: return "Reset Sariel?"
            case .pl: return "Zresetować Sariel?"
            }
        }

        static var resetConfirmButton: String {
            switch lang {
            case .en: return "Reset everything"
            case .pl: return "Resetuj wszystko"
            }
        }

        static var cancelButton: String {
            switch lang {
            case .en: return "Cancel"
            case .pl: return "Anuluj"
            }
        }

        static var resetConfirmMessage: String {
            switch lang {
            case .en: return "This permanently deletes all conversations, journal entries, and settings, then restarts the app. This cannot be undone."
            case .pl: return "Ta operacja trwale usuwa wszystkie rozmowy, wpisy w dzienniku i ustawienia, a następnie restartuje aplikację. Nie da się jej cofnąć."
            }
        }
        
        static var autoStartOllamaLabel: String {
            switch lang {
            case .en: return "Start Ollama automatically"
            case .pl: return "Uruchamiaj Ollamę automatycznie"
            }
        }

        static var autoStartOllamaDescription: String {
            switch lang {
            case .en: return "When enabled, Sariel starts the Ollama server in the background on launch if it isn't already running, and stops it when Sariel quits. Requires Ollama installed via Homebrew or the official installer."
            case .pl: return "Po włączeniu tej opcji, Sariel uruchamia serwer Ollamy w tle przy starcie, jeśli jeszcze nie działa, i zatrzymuje go przy zamknięciu Sariela. Wymaga Ollamy zainstalowanej przez Homebrew lub oficjalny instalator."
            }
        }
        
        static var shortcutsSectionTitle: String {
            switch lang {
            case .en: return "KEYBOARD SHORTCUTS"
            case .pl: return "SKRÓTY KLAWISZOWE"
            }
        }
    }
}
