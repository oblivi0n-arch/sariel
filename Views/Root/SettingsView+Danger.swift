import SwiftUI
import SwiftData
import AppKit

extension SettingsView {
    var dangerZone: some View {
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
    }
    
    @ViewBuilder
    var resetConfirmationOverlayContent: some View {
        if showResetConfirmation {
            ResetConfirmationOverlay(
                conversations: dataCounts.conversations,
                journalEntries: dataCounts.journalEntries,
                commitments: dataCounts.commitments,
                onConfirm: {
                    showResetConfirmation = false
                    resetEverything()
                },
                onCancel: {
                    showResetConfirmation = false
                }
            )
        }
    }
    
    private var dataCounts: (conversations: Int, journalEntries: Int, commitments: Int) {
        let conversations = (try? modelContext.fetchCount(FetchDescriptor<Conversation>())) ?? 0
        let journalEntries = (try? modelContext.fetchCount(FetchDescriptor<JournalEntry>())) ?? 0
        let commitments = (try? modelContext.fetchCount(FetchDescriptor<Commitment>())) ?? 0
        return (conversations, journalEntries, commitments)
    }
    
    private func resetEverything(skipOnboarding: Bool = false) {
        deleteAll(JournalEntry.self)
        deleteAll(JournalEntryTag.self)
        deleteAll(Conversation.self)
        deleteAll(Commitment.self)
        deleteAll(AchievementUnlock.self)
        
        try? modelContext.save()
        
        hasCompletedOnboarding = skipOnboarding
        isPostReset = !skipOnboarding
        
        host = OllamaDefaults.host
        model = OllamaDefaults.model
        useJournalContext = false
        useCredibilityContext = false
        autoStartOllama = false
        ollamaExecutablePath = ""

        dashboardShortcut = ShortcutAction.dashboard.defaultShortcut
        chatShortcut = ShortcutAction.chat.defaultShortcut
        journalShortcut = ShortcutAction.journal.defaultShortcut
        tribunalShortcut = ShortcutAction.tribunal.defaultShortcut
        
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "dashboardGreetingIndex")
        UserDefaults.standard.removeObject(forKey: "dashboardGreetingDate")
        UserDefaults.standard.removeObject(forKey: "lastDashboardShownDate")
        UserDefaults.standard.removeObject(forKey: "achievement_hasBeenPoorCredibility")
        
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
    
#if DEBUG
    var debugOnboardingSection: some View {
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
            
            Button("Force unlock all achievements") {
                forceUnlockAllAchievements()
            }
            .font(Typography.caption)
            .buttonStyle(.plain)
            .foregroundStyle(Theme.textMuted)

            Button("Reset achievements progress") {
                resetAchievementsProgress()
            }
            .font(Typography.caption)
            .buttonStyle(.plain)
            .foregroundStyle(Theme.textMuted)
            
            Button("Preview achievement toast") {
                toastManager.showAchievementUnlocked(.nightOwl)
            }
            .font(Typography.caption)
            .buttonStyle(.plain)
            .foregroundStyle(Theme.textMuted)
        }
    }
    
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
    
    private func forceUnlockAllAchievements() {
        var existing = (try? modelContext.fetch(FetchDescriptor<AchievementUnlock>())) ?? []
        let existingKinds = Set(existing.compactMap { $0.achievementKind })

        for kind in AchievementKind.allCases where !existingKinds.contains(kind) {
            let unlock = AchievementUnlock(kind: kind)
            modelContext.insert(unlock)
            existing.append(unlock)
        }

        for unlock in existing {
            guard let kind = unlock.achievementKind else { continue }
            unlock.progress = kind.targetCount ?? 1
            unlock.unlockedAt = Date()
        }

        try? modelContext.save()
    }

    private func resetAchievementsProgress() {
        let all = (try? modelContext.fetch(FetchDescriptor<AchievementUnlock>())) ?? []
        for unlock in all {
            unlock.progress = 0
            unlock.unlockedAt = nil
        }
        UserDefaults.standard.removeObject(forKey: "achievement_hasBeenPoorCredibility")
        try? modelContext.save()
    }
#endif
}

extension L10n.Settings {
    static var dangerZoneTitle: String {
        switch L10n.lang {
        case .en: return "DANGER ZONE"
        case .pl: return "STREFA NIEBEZPIECZEŃSTWA"
        }
    }
    
    static var resetButton: String {
        switch L10n.lang {
        case .en: return "RESET"
        case .pl: return "RESETUJ"
        }
    }
    
    static var resetDescription: String {
        switch L10n.lang {
        case .en: return "This option resets everything, including all conversations, journal entries, and your Ollama settings. The app will restart. This cannot be undone."
        case .pl: return "Ta opcja resetuje wszystko, w tym wszystkie rozmowy, wpisy w dzienniku i ustawienia Ollama. Aplikacja zostanie zrestartowana. Tej operacji nie da się cofnąć."
        }
    }
    
    static var resetConfirmTitle: String {
        switch L10n.lang {
        case .en: return "Reset Sariel?"
        case .pl: return "Zresetować Sariel?"
        }
    }
    
    static var resetConfirmButton: String {
        switch L10n.lang {
        case .en: return "Reset everything"
        case .pl: return "Resetuj wszystko"
        }
    }
    
    static var cancelButton: String {
        switch L10n.lang {
        case .en: return "Cancel"
        case .pl: return "Anuluj"
        }
    }
    
    static func resetConfirmMessage(conversations: Int, journalEntries: Int, commitments: Int) -> String {
        switch L10n.lang {
        case .en:
            return "This permanently deletes \(conversations) conversations, \(journalEntries) journal entries, and \(commitments) commitments, then restarts the app. This cannot be undone."
        case .pl:
            return "Usuniesz bezpowrotnie \(conversations) rozmów, \(journalEntries) wpisów w dzienniku i \(commitments) zobowiązań, a aplikacja zostanie zrestartowana. Tej operacji nie da się cofnąć."
        }
    }
    
    static var resetConfirmPhrase: String {
        switch L10n.lang {
        case .en: return "CLEAR THE MIRROR"
        case .pl: return "OCZYŚĆ LUSTRO"
        }
    }

    static func resetTypeToConfirmLabel(phrase: String) -> String {
        switch L10n.lang {
        case .en: return "Type \"\(phrase)\" to confirm."
        case .pl: return "Wpisz \"\(phrase)\", żeby potwierdzić."
        }
    }
}
