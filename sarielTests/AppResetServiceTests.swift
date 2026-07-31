import Testing
import SwiftData
import Foundation
@testable import sariel

struct AppResetServiceTests {
    
    // Note: wipeAllDataRemovesPinAndDisablesAppLock touches the real
    // macOS Keychain (no mocking layer exists for PinKeychainStore).
    // It temporarily overwrites and then deletes whatever PIN is stored
    // under this app's Keychain entry — safe on a dev machine with no
    // PIN in daily use, but worth remembering if that ever changes.

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([
            Conversation.self,
            ChatMessage.self,
            JournalEntry.self,
            JournalEntryTag.self,
            Commitment.self,
            AchievementUnlock.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return ModelContext(container)
    }

    @Test @MainActor
    func wipeAllDataRemovesPinAndDisablesAppLock() throws {
        let context = try makeInMemoryContext()

        _ = PinKeychainStore.savePinHash("1234")
        UserDefaults.standard.set(true, forKey: "appLockEnabled")
        #expect(PinKeychainStore.hasPinSet() == true)

        AppResetService.wipeAllData(context: context)

        #expect(PinKeychainStore.hasPinSet() == false)
        #expect(PinKeychainStore.verifyPin("1234") == false)
        #expect(UserDefaults.standard.bool(forKey: "appLockEnabled") == false)
    }

    @Test @MainActor
    func wipeAllDataDeletesAllModelObjects() throws {
        let context = try makeInMemoryContext()

        let conversation = Conversation()
        context.insert(conversation)
        let entry = JournalEntry(title: "t", content: "c")
        context.insert(entry)
        let commitment = Commitment(declarationText: "d", failureMeaning: "f")
        context.insert(commitment)
        let unlock = AchievementUnlock(kind: .nightOwl)
        context.insert(unlock)
        try context.save()

        AppResetService.wipeAllData(context: context)

        #expect(try context.fetch(FetchDescriptor<Conversation>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<JournalEntry>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Commitment>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<AchievementUnlock>()).isEmpty)
    }
}
