import Foundation
import SwiftData

enum AppResetService {
    static func wipeAllData(context: ModelContext) {
        deleteAll(JournalEntry.self, in: context)
        deleteAll(JournalEntryTag.self, in: context)
        deleteAll(Conversation.self, in: context)
        deleteAll(Commitment.self, in: context)
        deleteAll(AchievementUnlock.self, in: context)
        deleteAll(SelfLetter.self, in: context)
        try? context.save()

        PinKeychainStore.removePin()
        UserDefaults.standard.set(false, forKey: "appLockEnabled")
        UserDefaults.standard.set(OllamaDefaults.host, forKey: "ollamaHost")
        UserDefaults.standard.set(OllamaDefaults.model, forKey: "ollamaModel")
        UserDefaults.standard.set(false, forKey: "useJournalContext")
        UserDefaults.standard.set(false, forKey: "useCredibilityContext")
        UserDefaults.standard.set(false, forKey: "autoStartOllama")
        UserDefaults.standard.set("", forKey: "ollamaExecutablePath")

        UserDefaults.standard.set(ShortcutAction.dashboard.defaultShortcut.rawValue, forKey: ShortcutAction.dashboard.storageKey)
        UserDefaults.standard.set(ShortcutAction.chat.defaultShortcut.rawValue, forKey: ShortcutAction.chat.storageKey)
        UserDefaults.standard.set(ShortcutAction.journal.defaultShortcut.rawValue, forKey: ShortcutAction.journal.storageKey)
        UserDefaults.standard.set(ShortcutAction.tribunal.defaultShortcut.rawValue, forKey: ShortcutAction.tribunal.storageKey)

        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "aboutMe")
        UserDefaults.standard.removeObject(forKey: "hasCompletedAcquaintance")
        UserDefaults.standard.removeObject(forKey: "hasStartedAcquaintance")
        UserDefaults.standard.removeObject(forKey: "dashboardGreetingIndex")
        UserDefaults.standard.removeObject(forKey: "dashboardGreetingDate")
        UserDefaults.standard.removeObject(forKey: "lastDashboardShownDate")
        UserDefaults.standard.removeObject(forKey: "achievement_hasBeenPoorCredibility")

        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(true, forKey: "isPostReset")
        
        UserDefaults.standard.removeObject(forKey: "appTheme")
        UserDefaults.standard.set(false, forKey: "appThemeFollowsSystem")
    }

    private static func deleteAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) {
        guard let objects = try? context.fetch(FetchDescriptor<T>()) else { return }
        for object in objects {
            context.delete(object)
        }
    }
}
