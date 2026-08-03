import SwiftUI
import SwiftData

extension SettingsView {
    var dangerZone: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "exclamationmark.triangle", title: L10n.Settings.dangerZoneTitle) {
                EmptyView()
            }
            
            DangerButton(title: L10n.Settings.resetButton) {
                showResetConfirmation = true
            }
            
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
                selfLetters: dataCounts.selfLetters,
                meditationSessions: dataCounts.meditationSessions,
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
    
    private var dataCounts: (conversations: Int, journalEntries: Int, commitments: Int, unlockedAchievements: Int, selfLetters: Int, meditationSessions: Int) {
        let conversations = (try? modelContext.fetchCount(FetchDescriptor<Conversation>())) ?? 0
        let journalEntries = (try? modelContext.fetchCount(FetchDescriptor<JournalEntry>())) ?? 0
        let commitments = (try? modelContext.fetchCount(FetchDescriptor<Commitment>())) ?? 0
        let unlockedAchievements = (try? modelContext.fetchCount(
            FetchDescriptor<AchievementUnlock>(predicate: #Predicate { $0.unlockedAt != nil })
        )) ?? 0
        let selfLetters = (try? modelContext.fetchCount(FetchDescriptor<SelfLetter>())) ?? 0
        let meditationSessions = (try? modelContext.fetchCount(FetchDescriptor<MeditationSession>())) ?? 0
        return (conversations, journalEntries, commitments, unlockedAchievements, selfLetters, meditationSessions)
    }
    
    func resetEverything(skipOnboarding: Bool = false) {
        AppResetService.wipeAllData(context: modelContext)

        if skipOnboarding {
            hasCompletedOnboarding = true
            isPostReset = false
        }

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
    
    static func resetConfirmMessage(conversations: Int, journalEntries: Int, commitments: Int, unlockedAchievements: Int, selfLetters: Int, meditationSessions: Int) -> String {
        switch L10n.lang {
        case .en:
            return "This permanently deletes \(conversations) conversations, \(journalEntries) journal entries, \(commitments) commitments, \(unlockedAchievements) unlocked achievements, \(selfLetters) letters to yourself, and \(meditationSessions) meditation sessions, then restarts the app. This cannot be undone."
        case .pl:
            return "Usuniesz bezpowrotnie \(conversations) rozmów, \(journalEntries) wpisów w dzienniku, \(commitments) zobowiązań, \(unlockedAchievements) odblokowanych osiągnięć, \(selfLetters) listów do siebie i \(meditationSessions) sesji medytacji, a aplikacja zostanie zrestartowana. Tej operacji nie da się cofnąć."
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
