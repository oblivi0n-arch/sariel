import Foundation
import SwiftData

extension ChatService {
    func startAcquaintance(for conversation: Conversation, modelContext: ModelContext) async {
        conversation.isAcquaintance = true
        UserDefaults.standard.set(true, forKey: "hasStartedAcquaintance")
        
        let guideMessage = ChatMessage(role: .guide, content: "")
        guideMessage.conversation = conversation
        conversation.messages.append(guideMessage)
        modelContext.insert(guideMessage)
        try? modelContext.save()

        await runAcquaintance(into: guideMessage, for: conversation, modelContext: modelContext)
    }

    func retryAcquaintance(for conversation: Conversation, modelContext: ModelContext) async {
        let sorted = conversation.messages.sorted { $0.timestamp < $1.timestamp }
        guard let guideMessage = sorted.first, guideMessage.messageRole == .guide else { return }
        guideMessage.content = ""

        await runAcquaintance(into: guideMessage, for: conversation, modelContext: modelContext)
    }

    func runAcquaintance(into guideMessage: ChatMessage, for conversation: Conversation, modelContext: ModelContext) async {
        generatingConversationIDs.insert(conversation.id)
        lastErrors[conversation.id] = nil

        do {
            for try await chunk in client.streamChat(messages: PromptBuilder.buildAcquaintanceMessages()) {
                guideMessage.content += chunk
            }
        } catch {
            let message = (error as? OllamaError)?.errorDescription ?? error.localizedDescription
            lastErrors[conversation.id] = message
            if guideMessage.content.isEmpty {
                guideMessage.content = "⚠️ \(message)"
            }
        }

        generatingConversationIDs.remove(conversation.id)

        if !guideMessage.content.isEmpty, !guideMessage.content.hasPrefix("⚠️") {
            let question = guideMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
            conversation.acquaintanceQuestion = question

            if let title = try? await client.complete(messages: PromptBuilder.buildAcquaintanceTitleMessages(question: question)) {
                let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanedTitle.isEmpty {
                    conversation.title = cleanedTitle
                }
            }
        }

        try? modelContext.save()
    }

    func acquaintanceTag(modelContext: ModelContext) -> JournalEntryTag {
        let descriptor = FetchDescriptor<JournalEntryTag>()
        if let allTags = try? modelContext.fetch(descriptor),
           let existing = allTags.first(where: { $0.name.caseInsensitiveCompare(L10n.Acquaintance.tagName) == .orderedSame }) {
            return existing
        }
        let tag = JournalEntryTag(name: L10n.Acquaintance.tagName)
        modelContext.insert(tag)
        return tag
    }
}

extension L10n {
    enum Acquaintance {
        static func tagName(for language: AppLanguage) -> String {
            switch language {
            case .en: return "acquaintance"
            case .pl: return "zapoznanie"
            }
        }

        static var tagName: String { tagName(for: lang) }

        static var allTagNameVariants: [String] {
            AppLanguage.allCases.map { tagName(for: $0) }
        }
    }
}
