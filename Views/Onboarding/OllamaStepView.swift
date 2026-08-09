import SwiftUI

struct OllamaStepView: View {
    let onFinish: () -> Void
    let onBack: () -> Void

    @EnvironmentObject private var connectionMonitor: ConnectionMonitor
    @AppStorage("ollamaHost") private var host: String = OllamaDefaults.host
    @AppStorage("ollamaModel") private var model: String = OllamaDefaults.model

    @State private var availableModels: [String] = []
    @State private var isLoadingModels = false
    @State private var modelsLoadError: String?
    @State private var isBackHovering = false
    @State private var isFinishHovering = false

    private var isHostValid: Bool {
        guard let url = URL(string: host), let scheme = url.scheme else { return false }
        return (scheme == "http" || scheme == "https") && url.host != nil
    }
    
    private var isHostLocal: Bool {
        guard let hostname = URL(string: host)?.host?.lowercased() else { return false }
        return hostname == "localhost" || hostname == "127.0.0.1" || hostname == "::1"
    }

    private var finishLabel: String {
        connectionMonitor.isConnected ? L10n.Wizard.finish : L10n.Wizard.skipForNow
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(L10n.Wizard.ollamaPrompt)
                .font(Theme.voiceFont)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            connectionBadge

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Settings.hostFieldLabel)
                    .font(Typography.label)
                    .foregroundStyle(Theme.textMuted)

                PlaceholderTextField(placeholder: L10n.Settings.hostFieldLabel, text: $host)
                    .padding(10)
                    .background(Theme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(host.isEmpty || isHostValid ? Theme.border : Color.red.opacity(0.6), lineWidth: host.isEmpty || isHostValid ? 0.5 : 1)
                    )

                if !host.isEmpty && !isHostValid {
                    Text(L10n.Settings.hostFieldError)
                        .font(Typography.caption)
                        .foregroundStyle(Color.red.opacity(0.8))
                }
                
                if isHostValid && !isHostLocal {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(Typography.caption)
                        Text(L10n.Settings.remoteHostWarning)
                            .font(Typography.caption)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(Color.orange.opacity(0.85))
                }
            }
            .frame(maxWidth: 320)

            modelPicker
                .frame(maxWidth: 320)

            Text(L10n.Wizard.skipHint)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
                .multilineTextAlignment(.center)

            HStack(spacing: 24) {
                Text(L10n.Wizard.back)
                    .font(Typography.label)
                    .foregroundStyle(isBackHovering ? Theme.textPrimary : Theme.textMuted)
                    .onTapGesture(perform: onBack)
                    .onHover { hovering in isBackHovering = hovering }

                Text(finishLabel)
                    .font(Typography.label)
                    .foregroundStyle(isFinishHovering ? Theme.textPrimary : Theme.textMuted)
                    .onTapGesture(perform: onFinish)
                    .onHover { hovering in isFinishHovering = hovering }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: 420)
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
        }
    }

    private struct OllamaTagsResponse: Codable {
        let models: [OllamaModelInfo]
    }

    private struct OllamaModelInfo: Codable {
        let name: String
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
}

extension L10n.Wizard {
    static var ollamaPrompt: String {
        switch L10n.lang {
        case .en: return "Sariel needs a local model to speak through. Connect to Ollama, or skip for now."
        case .pl: return "Sariel potrzebuje lokalnego modelu, żeby przemówić. Połącz się z Ollamą albo pomiń na razie."
        }
    }

    static var finish: String {
        switch L10n.lang {
        case .en: return "finish"
        case .pl: return "zakończ"
        }
    }

    static var skipForNow: String {
        switch L10n.lang {
        case .en: return "skip for now"
        case .pl: return "pomiń na razie"
        }
    }

    static var skipHint: String {
        switch L10n.lang {
        case .en: return "You can set this up anytime later in Settings."
        case .pl: return "Możesz to skonfigurować w dowolnym momencie w Ustawieniach."
        }
    }
}
