import SwiftUI
import SwiftData
import AppKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var connectionMonitor: ConnectionMonitor
    @Binding var isPresented: Bool

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("isPostReset") private var isPostReset: Bool = false
    @AppStorage("ollamaHost") private var host: String = "http://localhost:11434"
    @AppStorage("ollamaModel") private var model: String = "gemma3:12b"
    @AppStorage("useJournalContext") private var useJournalContext: Bool = false

    @State private var availableModels: [String] = []
    @State private var isLoadingModels = false
    @State private var modelsLoadError: String?
    @State private var showResetConfirmation = false

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
                    contextSection
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

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "book.closed", title: "JOURNAL CONTEXT") {
                EmptyView()
            }

            Toggle(isOn: $useJournalContext) {
                Text("Let Sariel read your recent journal entries")
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textPrimary)
            }
            .toggleStyle(.switch)
            .tint(Theme.textPrimary)

            Text("When enabled, your last \(PromptBuilder.journalContextEntryCount) journal entries are sent as context in every conversation, so Sariel can notice patterns over time. Entries never leave your device.")
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "exclamationmark.triangle", title: "DANGER ZONE") {
                EmptyView()
            }

            Button(action: { showResetConfirmation = true }) {
                Text("RESET")
                    .font(Typography.label)
                    .foregroundStyle(Color.red.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.4), lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            Text("This option resets everything, including all conversations, journal entries, and your Ollama settings. The app will restart. This cannot be undone.")
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
        .confirmationDialog(
            "Reset Sariel?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset everything", role: .destructive) {
                resetEverything()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all conversations, journal entries, and settings, then restarts the app. This cannot be undone.")
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
                Text("Model")
                    .font(Typography.label)
                    .foregroundStyle(Theme.textMuted)
                
                Spacer()
                
                Button(action: { Task { await fetchAvailableModels() } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                        Text(isLoadingModels ? "loading..." : "load models")
                    }
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
                .disabled(isLoadingModels)
            }
            
            if isLoadingModels {
                Text("Loading models...")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
            } else if let modelsLoadError {
                Text(modelsLoadError)
                    .font(Typography.caption)
                    .foregroundStyle(Color.red.opacity(0.8))
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
            
            Text("Recommended: gemma4:e4b — natively supports system-role instructions, which this app relies on heavily (personality prompt, journal context, conversation summary). Smaller or older models may struggle with memory and long context.")
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

        host = "http://localhost:11434"
        model = "gemma3:12b"
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

