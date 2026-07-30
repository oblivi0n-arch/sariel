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
                unlockedAchievements: dataCounts.unlockedAchievements,
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
    
    private var dataCounts: (conversations: Int, journalEntries: Int, commitments: Int, unlockedAchievements: Int) {
        let conversations = (try? modelContext.fetchCount(FetchDescriptor<Conversation>())) ?? 0
        let journalEntries = (try? modelContext.fetchCount(FetchDescriptor<JournalEntry>())) ?? 0
        let commitments = (try? modelContext.fetchCount(FetchDescriptor<Commitment>())) ?? 0
        let unlockedAchievements = (try? modelContext.fetchCount(
            FetchDescriptor<AchievementUnlock>(predicate: #Predicate { $0.unlockedAt != nil })
        )) ?? 0
        return (conversations, journalEntries, commitments, unlockedAchievements)
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
        UserDefaults.standard.removeObject(forKey: "aboutMe")
        UserDefaults.standard.removeObject(forKey: "hasCompletedAcquaintance")
        UserDefaults.standard.removeObject(forKey: "hasStartedAcquaintance")
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
        case .en: return "This resets everything — all your data and settings. The app will restart. This cannot be undone."
        case .pl: return "Ta opcja resetuje wszystko — wszystkie Twoje dane i ustawienia. Aplikacja zostanie zrestartowana. Tej operacji nie da się cofnąć."
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
    
    static func resetConfirmMessage(conversations: Int, journalEntries: Int, commitments: Int, unlockedAchievements: Int) -> String {
        switch L10n.lang {
        case .en:
            return "This permanently deletes \(conversations) conversations, \(journalEntries) journal entries, \(commitments) commitments, and \(unlockedAchievements) unlocked achievements, then restarts the app. This cannot be undone."
        case .pl:
            return "Usuniesz bezpowrotnie \(conversations) rozmów, \(journalEntries) wpisów w dzienniku, \(commitments) zobowiązań i \(unlockedAchievements) odblokowanych osiągnięć, a aplikacja zostanie zrestartowana. Tej operacji nie da się cofnąć."
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
