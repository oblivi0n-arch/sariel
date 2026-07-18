import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var connectionMonitor: ConnectionMonitor
    @Binding var isPresented: Bool

    @AppStorage("ollamaHost") private var host: String = "http://localhost:11434"
    @AppStorage("ollamaModel") private var model: String = "gemma3:12b"
    @AppStorage("customSystemPrompt") private var customPrompt: String = ""

    @State private var availableModels: [String] = []
    @State private var isLoadingModels = false
    @State private var modelsLoadError: String?

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
                    ollamaSection
                    personalitySection
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

            Text("settings")
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
            sectionHeader(icon: "network", title: "OLLAMA CLIENT") {
                connectionBadge
            }

            labeledField(
                title: "Host",
                text: $host,
                isValid: host.isEmpty || isHostValid,
                errorMessage: "Enter a valid URL, e.g. http://localhost:11434"
            )
            modelPicker
        }
    }

    private var connectionBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(connectionMonitor.isConnected ? Theme.textPrimary : Theme.textFaint)
                .frame(width: 6, height: 6)
            Text(connectionMonitor.isConnected ? "connected" : "offline")
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
    }

    private var personalitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "text.quote", title: "SARIEL PERSONALITY") {
                Button(action: resetPrompt) {
                    Text("restore default")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textMuted)
                        .underline()
                }
                .buttonStyle(.plain)
                .opacity(customPrompt.isEmpty ? 0.4 : 1)
                .disabled(customPrompt.isEmpty)
            }

            ZStack(alignment: .topLeading) {
                if customPrompt.isEmpty {
                    Text(PromptBuilder.systemPrompt)
                        .font(Theme.voiceFont)
                        .foregroundStyle(Theme.textFaint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $customPrompt)
                    .font(Theme.voiceFont)
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .frame(height: 260)
            .background(Theme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
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
            Text("Model")
                .font(Typography.label)
                .foregroundStyle(Theme.textMuted)

            if isLoadingModels {
                Text("Loading models...")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
            } else if let modelsLoadError {
                HStack(spacing: 8) {
                    Text(modelsLoadError)
                        .font(Typography.caption)
                        .foregroundStyle(Color.red.opacity(0.8))

                    Button(action: { Task { await fetchAvailableModels() } }) {
                        Text("retry")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.textPrimary)
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
            } else if availableModels.isEmpty {
                Text("No models found")
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

    private func resetPrompt() {
        customPrompt = ""
    }

    private func fetchAvailableModels() async {
        guard isHostValid, let url = URL(string: "\(host)/api/tags") else {
            modelsLoadError = "Fix the host URL first"
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
            modelsLoadError = "Could not load models. Is Ollama running?"
            availableModels = []
        }

        isLoadingModels = false
    }
}
