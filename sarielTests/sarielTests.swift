import Testing
import SwiftData
import Foundation
@testable import sariel

struct DataExportRoundTripTests {

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
    func exportAndImportPreservesAllData() throws {
        let sourceContext = try makeInMemoryContext()

        let conversation = Conversation(title: "Testowa rozmowa")
        conversation.summary = "Podsumowanie testowe"
        conversation.isTribunal = true
        sourceContext.insert(conversation)

        let message = ChatMessage(role: .user, content: "Treść testowej wiadomości")
        message.conversation = conversation
        sourceContext.insert(message)

        let tag = JournalEntryTag(name: "test-tag")
        sourceContext.insert(tag)

        let entry = JournalEntry(title: "Testowy wpis", content: "Treść wpisu", mood: .good)
        entry.sourceConversation = conversation
        entry.tags = [tag]
        sourceContext.insert(entry)

        let commitment = Commitment(declarationText: "Testowe zobowiązanie", failureMeaning: "Testowe znaczenie porażki")
        commitment.sourceMessage = message
        commitment.resolvingConversation = conversation
        sourceContext.insert(commitment)

        let unlock = AchievementUnlock(kind: .nightOwl)
        unlock.progress = 3
        unlock.unlockedAt = Date()
        sourceContext.insert(unlock)

        try sourceContext.save()

        let export = try DataExportService.exportAllData(modelContext: sourceContext)
        let jsonData = try DataExportService.encodeToJSON(export)
        let decodedExport = try DataExportService.decodeFromJSON(jsonData)

        let targetContext = try makeInMemoryContext()
        try DataExportService.importAllData(decodedExport, modelContext: targetContext)

        let importedConversations = try targetContext.fetch(FetchDescriptor<Conversation>())
        #expect(importedConversations.count == 1)
        let importedConversation = try #require(importedConversations.first)
        #expect(importedConversation.title == "Testowa rozmowa")
        #expect(importedConversation.summary == "Podsumowanie testowe")
        #expect(importedConversation.isTribunal == true)

        let importedMessages = try targetContext.fetch(FetchDescriptor<ChatMessage>())
        let importedMessage = try #require(importedMessages.first)
        #expect(importedMessage.content == "Treść testowej wiadomości")
        #expect(importedMessage.conversation?.id == importedConversation.id)

        let importedEntries = try targetContext.fetch(FetchDescriptor<JournalEntry>())
        let importedEntry = try #require(importedEntries.first)
        #expect(importedEntry.title == "Testowy wpis")
        #expect(importedEntry.sourceConversation?.id == importedConversation.id)
        #expect(importedEntry.tags.count == 1)
        #expect(importedEntry.tags.first?.name == "test-tag")

        let importedCommitments = try targetContext.fetch(FetchDescriptor<Commitment>())
        let importedCommitment = try #require(importedCommitments.first)
        #expect(importedCommitment.declarationText == "Testowe zobowiązanie")
        #expect(importedCommitment.sourceMessage?.id == importedMessage.id)
        #expect(importedCommitment.resolvingConversation?.id == importedConversation.id)

        let importedUnlocks = try targetContext.fetch(FetchDescriptor<AchievementUnlock>())
        let importedUnlock = try #require(importedUnlocks.first)
        #expect(importedUnlock.progress == 3)
        #expect(importedUnlock.unlockedAt != nil)
    }
}
