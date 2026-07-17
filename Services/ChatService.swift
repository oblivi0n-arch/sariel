import Foundation
import Combine
import SwiftData

@MainActor
final class ChatService: ObservableObject {
    @Published var generatingConversationIDs: Set<UUID> = []
    @Published var endingConversationIDs: Set<UUID> = []
    @Published var lastErrors: [UUID: String] = [:]
    @Published var endConversationErrors: [UUID: String] = [:]

    private let client: OllamaClient
    
    @MainActor
    init() {
        self.client = OllamaClient()
    }

    func send(text: String, in conversation: Conversation, modelContext: ModelContext) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let hasSuccessfulExchange = conversation.messages.contains {
            $0.messageRole == .guide && !$0.content.isEmpty && !$0.content.hasPrefix("⚠️")
        }

        let userMessage = ChatMessage(role: .user, content: text)
        userMessage.conversation = conversation
        conversation.messages.append(userMessage)
        modelContext.insert(userMessage)

        let guideMessage = ChatMessage(role: .guide, content: "")
        guideMessage.conversation = conversation
        conversation.messages.append(guideMessage)
        modelContext.insert(guideMessage)

        try? modelContext.save()

        generatingConversationIDs.insert(conversation.id)
        lastErrors[conversation.id] = nil

        let history = conversation.messages
            .sorted { $0.timestamp < $1.timestamp }
            .filter { !$0.content.isEmpty }

        await streamGuideResponse(into: guideMessage, history: Array(history), conversation: conversation, modelContext: modelContext)

        generatingConversationIDs.remove(conversation.id)

        if !hasSuccessfulExchange && !guideMessage.content.hasPrefix("⚠️") {
            await generateTitle(for: conversation, userText: text, guideText: guideMessage.content, modelContext: modelContext)
        }
    }
    private func generateTitle(for conversation: Conversation, userText: String, guideText: String, modelContext: ModelContext) async {
        let titleMessages = PromptBuilder.buildTitleMessages(userText: userText, guideText: guideText)
        do {
            let title = try await client.complete(messages: titleMessages)
            let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                conversation.title = cleaned
                try? modelContext.save()
            }
        } catch {
            
        }
    }
    
    func endConversation(for conversation: Conversation, modelContext: ModelContext) async -> JournalEntry? {
        endingConversationIDs.insert(conversation.id)
        endConversationErrors[conversation.id] = nil
        defer { endingConversationIDs.remove(conversation.id) }

        let history = conversation.messages
            .sorted { $0.timestamp < $1.timestamp }
            .filter { !$0.content.isEmpty && !$0.content.hasPrefix("⚠️") }
        
        do {
            let content = try await client.complete(messages: PromptBuilder.buildJournalMessages(history: history))
            let title = try await client.complete(messages: PromptBuilder.buildJournalTitleMessages(entryContent: content))

            let entry = JournalEntry(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            entry.sourceConversation = conversation
            conversation.journalEntry = entry
            modelContext.insert(entry)
            entry.tags.append(generatedTag(modelContext: modelContext))
            try? modelContext.save()
            
            return entry
        } catch {
            endConversationErrors[conversation.id] = (error as? OllamaError)?.errorDescription ?? error.localizedDescription
                    return nil
        }
    }
    
    private func generatedTag(modelContext: ModelContext) -> JournalEntryTag {
        let descriptor = FetchDescriptor<JournalEntryTag>(
            predicate: #Predicate { $0.name == "generated" }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let tag = JournalEntryTag(name: "generated")
        modelContext.insert(tag)
        return tag

    }
    
    func deleteMessages(from message: ChatMessage, in conversation: Conversation, modelContext: ModelContext) {
        let cutoff = message.timestamp
        let toRemove = conversation.messages.filter { $0.timestamp >= cutoff }

        for msg in toRemove {
            conversation.messages.removeAll { $0.id == msg.id }
            modelContext.delete(msg)
        }
        try? modelContext.save()
    }
    
    func deleteMessages(after message: ChatMessage, in conversation: Conversation, modelContext: ModelContext) {
        let cutoff = message.timestamp
        let toRemove = conversation.messages.filter { $0.timestamp > cutoff }

        for msg in toRemove {
            conversation.messages.removeAll { $0.id == msg.id }
            modelContext.delete(msg)
        }
        try? modelContext.save()
    }
    
    private func streamGuideResponse(into guideMessage: ChatMessage, history: [ChatMessage], conversation: Conversation, modelContext: ModelContext) async {
        let messages = PromptBuilder.buildMessages(history: history)
        do {
            for try await chunk in client.streamChat(messages: messages) {
                guideMessage.content += chunk
            }
        } catch {
            let message = (error as? OllamaError)?.errorDescription ?? error.localizedDescription
            lastErrors[conversation.id] = message
            if guideMessage.content.isEmpty {
                guideMessage.content = "⚠️ \(message)"
            }
        }
        try? modelContext.save()
    }
    
    func retryLastResponse(for conversation: Conversation, modelContext: ModelContext) async {
        guard let guideMessage = conversation.messages
            .sorted(by: { $0.timestamp < $1.timestamp })
            .last(where: { $0.messageRole == .guide }) else { return }

        guideMessage.content = ""

        generatingConversationIDs.insert(conversation.id)
        lastErrors[conversation.id] = nil

        let history = conversation.messages
            .sorted { $0.timestamp < $1.timestamp }
            .filter { !$0.content.isEmpty }

        await streamGuideResponse(into: guideMessage, history: Array(history), conversation: conversation, modelContext: modelContext)

        generatingConversationIDs.remove(conversation.id)
    }
}
