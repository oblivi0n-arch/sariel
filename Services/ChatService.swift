import Foundation
import Combine
import SwiftData

@MainActor
final class ChatService: ObservableObject {
    @Published var isGenerating = false
    @Published var isEndingConversation = false
    @Published var lastError: String?

    private let client: OllamaClient
    private let modelContext: ModelContext
    
    @MainActor
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.client = OllamaClient()
    }

    func send(text: String, in conversation: Conversation) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let isFirstExchange = conversation.messages.isEmpty

        let userMessage = ChatMessage(role: .user, content: text)
        userMessage.conversation = conversation
        conversation.messages.append(userMessage)
        modelContext.insert(userMessage)

        let guideMessage = ChatMessage(role: .guide, content: "")
        guideMessage.conversation = conversation
        conversation.messages.append(guideMessage)
        modelContext.insert(guideMessage)

        try? modelContext.save()

        isGenerating = true
        lastError = nil

        let history = conversation.messages
            .sorted { $0.timestamp < $1.timestamp }
            .filter { !$0.content.isEmpty }

        let messages = PromptBuilder.buildMessages(history: Array(history))

        do {
            for try await chunk in client.streamChat(messages: messages) {
                guideMessage.content += chunk
            }
        } catch {
            let message = (error as? OllamaError)?.errorDescription ?? error.localizedDescription
            lastError = message
            if guideMessage.content.isEmpty {
                guideMessage.content = "⚠️ \(message)"
            }
        }

        try? modelContext.save()
        isGenerating = false

        if isFirstExchange && !guideMessage.content.hasPrefix("⚠️") {
            await generateTitle(for: conversation, userText: text, guideText: guideMessage.content)
        }
    }

    private func generateTitle(for conversation: Conversation, userText: String, guideText: String) async {
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
    
    func endConversation(for conversation: Conversation) async -> JournalEntry? {
        isEndingConversation = true
        lastError = nil
        defer { isEndingConversation = false }

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
            try? modelContext.save()
            
            return entry
        } catch {
            lastError = (error as? OllamaError)?.errorDescription ?? error.localizedDescription
            
            return nil
        }
    }
}
