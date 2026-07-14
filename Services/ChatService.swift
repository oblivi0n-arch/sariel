import Foundation
import Combine
import SwiftData

@MainActor
final class ChatService: ObservableObject {
    @Published var isGenerating = false
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
    }
}
