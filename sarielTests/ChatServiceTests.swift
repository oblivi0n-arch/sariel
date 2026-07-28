import Testing
import SwiftData
import Foundation
@testable import sariel

struct ChatServiceTests {

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
    func sendBlocksNewDeclarationWhenAtMaxPendingDeclarations() async throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()
        let conversation = Conversation()
        context.insert(conversation)

        for i in 0..<Commitment.maxPendingDeclarations {
            context.insert(Commitment(declarationText: "existing \(i)", failureMeaning: "f"))
        }
        try context.save()

        await chatService.send(
            text: "I declare I will meditate every morning",
            failureMeaning: "It would mean I don't follow through",
            in: conversation,
            modelContext: context
        )

        #expect(conversation.messages.isEmpty)
        let allCommitments = try context.fetch(FetchDescriptor<Commitment>())
        #expect(allCommitments.count == Commitment.maxPendingDeclarations)
    }

    @Test @MainActor
    func sendCreatesCommitmentOnlyWhenFailureMeaningIsProvided() async throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()
        let conversation = Conversation()
        context.insert(conversation)
        try context.save()

        await chatService.send(
            text: "I declare I will meditate every morning",
            failureMeaning: "It would mean I don't follow through",
            in: conversation,
            modelContext: context
        )

        let commitments = try context.fetch(FetchDescriptor<Commitment>())
        #expect(commitments.count == 1)
        #expect(commitments.first?.declarationText == "I declare I will meditate every morning")
    }

    @Test @MainActor
    func sendDoesNotCreateCommitmentWhenFailureMeaningIsEmpty() async throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()
        let conversation = Conversation()
        context.insert(conversation)
        try context.save()

        await chatService.send(
            text: "I declare I will meditate every morning",
            failureMeaning: "   ",
            in: conversation,
            modelContext: context
        )

        let commitments = try context.fetch(FetchDescriptor<Commitment>())
        #expect(commitments.isEmpty)
        #expect(conversation.messages.contains { $0.content == "I declare I will meditate every morning" })
    }

    @Test @MainActor
    func deleteMessagesFromIncludesTheCutoffMessageItself() throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()
        let conversation = Conversation()
        context.insert(conversation)

        let messages = (0..<3).map { i -> ChatMessage in
            let message = ChatMessage(role: .user, content: "message \(i)")
            message.timestamp = Date().addingTimeInterval(Double(i))
            message.conversation = conversation
            conversation.messages.append(message)
            context.insert(message)
            return message
        }
        try context.save()

        chatService.deleteMessages(from: messages[1], in: conversation, modelContext: context)

        #expect(conversation.messages.count == 1)
        #expect(conversation.messages.first?.content == "message 0")
    }

    @Test @MainActor
    func deleteMessagesAfterExcludesTheCutoffMessageItself() throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()
        let conversation = Conversation()
        context.insert(conversation)

        let messages = (0..<3).map { i -> ChatMessage in
            let message = ChatMessage(role: .user, content: "message \(i)")
            message.timestamp = Date().addingTimeInterval(Double(i))
            message.conversation = conversation
            conversation.messages.append(message)
            context.insert(message)
            return message
        }
        try context.save()

        chatService.deleteMessages(after: messages[1], in: conversation, modelContext: context)

        #expect(conversation.messages.count == 2)
        #expect(conversation.messages.contains { $0.content == "message 0" })
        #expect(conversation.messages.contains { $0.content == "message 1" })
    }

    @Test @MainActor
    func deletingMessagesBelowSummarizedCountClearsTheSummary() throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()
        let conversation = Conversation()
        conversation.summary = "OLD_SUMMARY"
        conversation.summarizedMessageCount = 4
        context.insert(conversation)

        let messages = (0..<4).map { i -> ChatMessage in
            let message = ChatMessage(role: .user, content: "message \(i)")
            message.timestamp = Date().addingTimeInterval(Double(i))
            message.conversation = conversation
            conversation.messages.append(message)
            context.insert(message)
            return message
        }
        try context.save()

        chatService.deleteMessages(from: messages[2], in: conversation, modelContext: context)

        #expect(conversation.messages.count == 2)
        #expect(conversation.summary == "")
        #expect(conversation.summarizedMessageCount == 2)
    }

    @Test @MainActor
    func summaryIsPreservedWhenEnoughMessagesRemainAfterDeletion() throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()
        let conversation = Conversation()
        conversation.summary = "OLD_SUMMARY"
        conversation.summarizedMessageCount = 2
        context.insert(conversation)

        let messages = (0..<5).map { i -> ChatMessage in
            let message = ChatMessage(role: .user, content: "message \(i)")
            message.timestamp = Date().addingTimeInterval(Double(i))
            message.conversation = conversation
            conversation.messages.append(message)
            context.insert(message)
            return message
        }
        try context.save()

        chatService.deleteMessages(from: messages[4], in: conversation, modelContext: context)

        #expect(conversation.messages.count == 4)
        #expect(conversation.summary == "OLD_SUMMARY")
        #expect(conversation.summarizedMessageCount == 2)
    }
}
