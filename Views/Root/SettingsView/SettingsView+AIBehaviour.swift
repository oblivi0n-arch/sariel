import SwiftUI

extension SettingsView {
    var ollamaSection: some View {
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
            
            ExpandableDescription(
                short: L10n.Settings.autoStartOllamaShortDescription,
                detail: L10n.Settings.autoStartOllamaDescription
      )
            
            manualOllamaPathDisclosure
            
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
    
    private var isHostValid: Bool {
        guard let url = URL(string: host), let scheme = url.scheme else { return false }
        return (scheme == "http" || scheme == "https") && url.host != nil
    }
    
    private var modelPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(L10n.Settings.modelFieldLabel)
                    .font(Typography.label)
                    .foregroundStyle(Theme.textMuted)

                Spacer()

                RefreshModelsButton(isLoading: isLoadingModels) {
                    Task { await fetchAvailableModels() }
                }
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
            
            ExpandableDescription(
                            short: L10n.Settings.modelRecommendationShortText,
                            detail: L10n.Settings.modelRecommendationText
                        )
                        .padding(.top, 2)
        }
    }
    
    private var isManualPathValid: Bool {
        ollamaExecutablePath.isEmpty || FileManager.default.isExecutableFile(atPath: ollamaExecutablePath)
    }
    
    private var manualOllamaPathDisclosure: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isManualPathShown.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Text(L10n.Settings.cantFindOllama)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .rotationEffect(.degrees(isManualPathShown ? 90 : 0))
                }
                .font(Typography.caption)
                .foregroundStyle(Theme.textMuted)
            }
            .buttonStyle(.plain)
            
            if isManualPathShown {
                labeledField(
                    title: L10n.Settings.manualPathLabel,
                    text: $ollamaExecutablePath,
                    isValid: isManualPathValid,
                    errorMessage: L10n.Settings.manualPathError
                )
                
                Text(L10n.Settings.manualPathHint)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
            }
        }
    }
    
    private func labeledField(title: String, text: Binding<String>, isValid: Bool = true, errorMessage: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Typography.label)
                .foregroundStyle(Theme.textMuted)

            PlaceholderTextField(placeholder: title, text: text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
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
    
    private struct OllamaTagsResponse: Codable {
        let models: [OllamaModelInfo]
    }
    
    private struct OllamaModelInfo: Codable {
        let name: String
    }
    
    func fetchAvailableModels() async {
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
    
    var contextSection: some View {
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
            
            ExpandableDescription(
            short: L10n.Settings.journalContextShortDescription(count: PromptBuilder.journalContextEntryCount),
                            detail: L10n.Settings.journalContextDescription(count: PromptBuilder.journalContextEntryCount)
                        )
        }
    }
    
    var credibilitySection: some View {
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
            
            ExpandableDescription(
                          short: L10n.Settings.credibilityShortDescription,
                           detail: L10n.Settings.credibilityDescription(minimum: CredibilityBand.sampleMinimum)
                        )
        }
    }
    
    var journalStyleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "text.alignleft", title: L10n.JournalStyle.sectionTitle) {
                EmptyView()
            }

            VStack(spacing: 8) {
                ForEach(JournalStyle.allCases, id: \.self) { style in
                    journalStyleOption(style)
                }
            }

            Text(L10n.JournalStyle.sectionHint)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
    }

    private func journalStyleOption(_ style: JournalStyle) -> some View {
        let isSelected = journalStyle == style

        return Button(action: { journalStyle = style }) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textFaint)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(style.displayName)
                        .font(Theme.uiFont)
                        .foregroundStyle(Theme.textPrimary)
                    Text(style.subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                }

                Spacer()
            }
            .padding(10)
            .contentShape(Rectangle())
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Theme.textPrimary.opacity(0.6) : Theme.border, lineWidth: isSelected ? 1 : 0.5)
            )
            .hoverBorder(cornerRadius: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct RefreshModelsButton: View {
    let isLoading: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10))
                Text(isLoading ? L10n.Settings.loadModelsButtonLoading : L10n.Settings.loadModelsButtonIdle)
            }
            .font(Typography.caption)
            .foregroundStyle(isHovering ? Theme.textPrimary : Theme.textMuted)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onHover { hovering in
            isHovering = hovering
            if hovering && !isLoading {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

extension L10n.Settings {
    static var ollamaSectionTitle: String {
        switch L10n.lang {
        case .en: return "OLLAMA CLIENT"
        case .pl: return "KLIENT OLLAMA"
        }
    }
    
    static var connectedStatus: String {
        switch L10n.lang {
        case .en: return "connected"
        case .pl: return "połączono"
        }
    }
    
    static var offlineStatus: String {
        switch L10n.lang {
        case .en: return "offline"
        case .pl: return "offline"
        }
    }
    
    static var hostFieldLabel: String {
        switch L10n.lang {
        case .en: return "Host"
        case .pl: return "Host"
        }
    }
    
    static var hostFieldError: String {
        switch L10n.lang {
        case .en: return "Enter a valid URL, e.g. http://localhost:11434"
        case .pl: return "Podaj prawidłowy adres URL, np. http://localhost:11434"
        }
    }
    
    static var modelFieldLabel: String {
        switch L10n.lang {
        case .en: return "Model"
        case .pl: return "Model"
        }
    }
    
    static var loadModelsButtonLoading: String {
        switch L10n.lang {
        case .en: return "loading..."
        case .pl: return "ładowanie..."
        }
    }
    
    static var loadModelsButtonIdle: String {
        switch L10n.lang {
        case .en: return "load models"
        case .pl: return "wczytaj modele"
        }
    }
    
    static var loadingModelsText: String {
        switch L10n.lang {
        case .en: return "Loading models..."
        case .pl: return "Wczytywanie modeli..."
        }
    }
    
    static var modelsLoadErrorGeneric: String {
        switch L10n.lang {
        case .en: return "Could not load models. Is Ollama running?"
        case .pl: return "Nie udało się wczytać modeli. Czy Ollama jest uruchomiona?"
        }
    }
    
    static var modelsLoadErrorHostInvalid: String {
        switch L10n.lang {
        case .en: return "Fix the host URL first"
        case .pl: return "Najpierw popraw adres hosta"
        }
    }
    
    static var noModelsFound: String {
        switch L10n.lang {
        case .en: return "No models found"
        case .pl: return "Nie znaleziono modeli"
        }
    }
    
    static var modelRecommendationText: String {
        switch L10n.lang {
        case .en: return "Recommended: gemma4:e4b — natively supports system-role instructions, which this app relies on heavily (personality prompt, journal context, conversation summary). Smaller or older models may struggle with memory and long context."
        case .pl: return "Zalecany: gemma4:e4b — natywnie wspiera instrukcje typu system-role, na których ta aplikacja mocno się opiera (prompt osobowości, kontekst dziennika, podsumowanie rozmowy). Mniejsze lub starsze modele mogą mieć problemy z pamięcią i długim kontekstem."
        }
    }
    
    static var autoStartOllamaLabel: String {
        switch L10n.lang {
        case .en: return "Start Ollama automatically"
        case .pl: return "Uruchamiaj Ollamę automatycznie"
        }
    }
    
    static var autoStartOllamaDescription: String {
        switch L10n.lang {
        case .en: return "When enabled, Sariel starts the Ollama server in the background on launch if it isn't already running, and stops it when Sariel quits. Requires Ollama installed via Homebrew or the official installer."
        case .pl: return "Po włączeniu tej opcji, Sariel uruchamia serwer Ollamy w tle przy starcie, jeśli jeszcze nie działa, i zatrzymuje go przy zamknięciu Sariela. Wymaga Ollamy zainstalowanej przez Homebrew lub oficjalny instalator."
        }
    }
    
    static var cantFindOllama: String {
        switch L10n.lang {
        case .en: return "Can't find Ollama?"
        case .pl: return "Nie możemy znaleźć Ollamy?"
        }
    }
    
    static var manualPathLabel: String {
        switch L10n.lang {
        case .en: return "Ollama executable path"
        case .pl: return "Ścieżka do pliku wykonywalnego Ollamy"
        }
    }
    
    static var manualPathError: String {
        switch L10n.lang {
        case .en: return "This path doesn't point to a valid executable file."
        case .pl: return "Ta ścieżka nie wskazuje na prawidłowy plik wykonywalny."
        }
    }
    
    static var manualPathHint: String {
        switch L10n.lang {
        case .en: return "Leave empty to auto-detect common install locations. Find yours by running \"which ollama\" in Terminal."
        case .pl: return "Zostaw puste, by automatycznie wykryć typowe lokalizacje instalacji. Znajdziesz swoją, wpisując \"which ollama\" w Terminalu."
        }
    }
    
    static var journalSectionTitle: String {
        switch L10n.lang {
        case .en: return "JOURNAL CONTEXT"
        case .pl: return "KONTEKST DZIENNIKA"
        }
    }
    
    static var journalContextToggleLabel: String {
        switch L10n.lang {
        case .en: return "Let Sariel read your recent journal entries"
        case .pl: return "Pozwól Sarielowi czytać Twoje ostatnie wpisy w dzienniku"
        }
    }
    
    static func journalContextDescription(count: Int) -> String {
        switch L10n.lang {
        case .en: return "When enabled, your last \(count) journal entries are sent as context in every conversation, so Sariel can notice patterns over time. Entries never leave your device."
        case .pl: return "Po włączeniu tej opcji, Twoje ostatnie \(count) wpisy w dzienniku są wysyłane jako kontekst w każdej rozmowie, dzięki czemu Sariel może zauważać powtarzające się wzorce. Wpisy nigdy nie opuszczają Twojego urządzenia."
        }
    }
    
    static var credibilitySectionTitle: String {
        switch L10n.lang {
        case .en: return "CREDIBILITY CONTEXT"
        case .pl: return "KONTEKST WIARYGODNOŚCI"
        }
    }
    
    static var credibilityToggleLabel: String {
        switch L10n.lang {
        case .en: return "Let Sariel factor in your track record on declarations"
        case .pl: return "Pozwól Sarielowi uwzględniać Twoją historię dotrzymywania deklaracji"
        }
    }
    
    static func credibilityDescription(minimum: Int) -> String {
        switch L10n.lang {
        case .en: return "When enabled, Sariel sees which of your declared commitments were fulfilled or broken from past Tribunal sessions, and adjusts its tone toward you accordingly. Requires at least \(minimum) resolved declarations."
        case .pl: return "Po włączeniu tej opcji, Sariel widzi które z Twoich zadeklarowanych zobowiązań zostały spełnione lub złamane podczas poprzednich sesji Trybunału, i dostosowuje do tego swój ton. Wymaga co najmniej \(minimum) rozstrzygniętych deklaracji."
        }
    }
    
    static var autoStartOllamaShortDescription: String {
        switch L10n.lang {
        case .en: return "Starts and stops the Ollama server automatically."
        case .pl: return "Automatycznie uruchamia i zatrzymuje serwer Ollamy."
        }
    }

    static var modelRecommendationShortText: String {
        switch L10n.lang {
        case .en: return "Recommended: gemma4:e4b"
        case .pl: return "Zalecany: gemma4:e4b"
        }
    }

    static func journalContextShortDescription(count: Int) -> String {
        switch L10n.lang {
        case .en: return "Sariel sees your last \(count) journal entries."
        case .pl: return "Sariel widzi Twoje ostatnie \(count) wpisy."
        }
    }

    static var credibilityShortDescription: String {
        switch L10n.lang {
        case .en: return "Sariel adjusts its tone based on your track record."
        case .pl: return "Sariel dostosowuje ton na podstawie Twojej historii."
        }
    }
}
