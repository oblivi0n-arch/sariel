import Foundation
import Combine
import SwiftData

@MainActor
final class ChatService: ObservableObject {
    @Published var generatingConversationIDs: Set<UUID> = []
    @Published var endingConversationIDs: Set<UUID> = []
    @Published var lastErrors: [UUID: String] = [:]
    @Published var endConversationErrors: [UUID: String] = [:]
    @Published var isGeneratingVerdicts: Set<UUID> = []
    @Published var verdictErrors: [UUID: String] = [:]

    let client: OllamaClient

    @MainActor
    init() {
        self.client = OllamaClient()
    }

    func send(text: String, failureMeaning: String? = nil, in conversation: Conversation, modelContext: ModelContext) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if !conversation.isTribunal, Commitment.isDeclaration(text) {
            let pendingCount = fetchPendingCommitments(modelContext: modelContext).count
            guard pendingCount < Commitment.maxPendingDeclarations else { return }
        }

        let hasSuccessfulExchange = conversation.messages.contains {
            $0.messageRole == .guide && $0.isValidExchange
        }

        let userMessage = ChatMessage(role: .user, content: text)
        userMessage.conversation = conversation
        conversation.messages.append(userMessage)
        modelContext.insert(userMessage)

        if !conversation.isTribunal, Commitment.isDeclaration(text) {
            let commitment = Commitment(declarationText: text, failureMeaning: failureMeaning ?? "", sourceMessage: userMessage)
            modelContext.insert(commitment)
        }

        let guideMessage = ChatMessage(role: .guide, content: "")
        guideMessage.conversation = conversation
        conversation.messages.append(guideMessage)
        modelContext.insert(guideMessage)

        try? modelContext.save()

        generatingConversationIDs.insert(conversation.id)
        lastErrors[conversation.id] = nil

        let history = conversation.messages
            .sorted { $0.timestamp < $1.timestamp }
            .filter { $0.isValidExchange }

        await streamGuideResponse(into: guideMessage, history: Array(history), conversation: conversation, modelContext: modelContext)

        generatingConversationIDs.remove(conversation.id)

        if !conversation.isTribunal {
            if !hasSuccessfulExchange && !guideMessage.content.hasPrefix("⚠️") {
                await generateTitle(for: conversation, userText: text, guideText: guideMessage.content, modelContext: modelContext)
            }
        }
        if !guideMessage.content.hasPrefix("⚠️") {
            Task { await refreshSummaryIfNeeded(for: conversation, modelContext: modelContext) }
        }
    }

    func retryLastResponse(for conversation: Conversation, modelContext: ModelContext) async {
        let sorted = conversation.messages.sorted { $0.timestamp < $1.timestamp }
        guard let guideMessage = sorted.last(where: { $0.messageRole == .guide }) else { return }

        let hasSuccessfulExchange = sorted.contains {
            $0.messageRole == .guide && $0.id != guideMessage.id && $0.isValidExchange
        }
        let precedingUserText = sorted.last(where: { $0.messageRole == .user && $0.timestamp < guideMessage.timestamp })?.content

        guideMessage.content = ""

        generatingConversationIDs.insert(conversation.id)
        lastErrors[conversation.id] = nil

        let history = conversation.messages
            .sorted { $0.timestamp < $1.timestamp }
            .filter { $0.isValidExchange }

        await streamGuideResponse(into: guideMessage, history: Array(history), conversation: conversation, modelContext: modelContext)

        generatingConversationIDs.remove(conversation.id)

        if !conversation.isTribunal {
            if !hasSuccessfulExchange, !guideMessage.content.hasPrefix("⚠️"), let userText = precedingUserText {
                await generateTitle(for: conversation, userText: userText, guideText: guideMessage.content, modelContext: modelContext)
            }
        }
        if !guideMessage.content.hasPrefix("⚠️") {
            Task { await refreshSummaryIfNeeded(for: conversation, modelContext: modelContext) }
        }
    }

    func streamGuideResponse(into guideMessage: ChatMessage, history: [ChatMessage], conversation: Conversation, modelContext: ModelContext) async {
        let messages: [OllamaMessage]
        if conversation.isTribunal {
            let pending = fetchPendingCommitments(modelContext: modelContext)
            messages = PromptBuilder.buildTribunalMessages(history: history, commitments: pending, summary: conversation.summary)
        } else {
            let journalContext = fetchJournalContextIfEnabled(modelContext: modelContext)
            let credibilityContext = fetchCredibilityContextIfEnabled(modelContext: modelContext)
            let username = UserDefaults.standard.string(forKey: "username")?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let aboutMe = UserDefaults.standard.string(forKey: "aboutMe")?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            messages = PromptBuilder.buildMessages(
                history: history,
                summary: conversation.summary,
                journalContext: journalContext,
                credibilityContext: credibilityContext,
                username: username,
                aboutMe: aboutMe
            )
        }

        var buffer = ""
        var lastFlush = Date()
        let flushInterval: TimeInterval = 0.08

        func flushBuffer() {
            guard !buffer.isEmpty else { return }
            guideMessage.content += buffer
            buffer = ""
        }

        do {
            for try await chunk in client.streamChat(messages: messages) {
                buffer += chunk

                let now = Date()
                if now.timeIntervalSince(lastFlush) >= flushInterval {
                    flushBuffer()
                    lastFlush = now
                }
            }
            flushBuffer()
        } catch {
            flushBuffer()

            let ollamaError = error as? OllamaError
            let description = ollamaError?.errorDescription ?? error.localizedDescription
            lastErrors[conversation.id] = description

            if guideMessage.content.isEmpty {
                var fullMessage = "⚠️ \(description)"
                if let suggestion = ollamaError?.recoverySuggestion {
                    fullMessage += "\n\(suggestion)"
                }
                guideMessage.content = fullMessage
            }
        }
        try? modelContext.save()
    }

    func endConversation(for conversation: Conversation, mood: Mood, modelContext: ModelContext) async -> JournalEntry? {
        endingConversationIDs.insert(conversation.id)
        endConversationErrors[conversation.id] = nil
        defer { endingConversationIDs.remove(conversation.id) }

        let history = conversation.messages
            .sorted { $0.timestamp < $1.timestamp }
            .filter { $0.isValidExchange }

        do {
            let content = try await client.complete(messages: PromptBuilder.buildJournalMessages(history: history))

            let title: String
            if conversation.isProvocation, let provocationTitle = conversation.provocationTitle {
                title = provocationTitle
            } else {
                let generated = try await client.complete(messages: PromptBuilder.buildJournalTitleMessages(entryContent: content))
                title = generated.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            let entry = JournalEntry(
                title: title,
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                mood: mood
            )
            entry.sourceConversation = conversation
            conversation.journalEntry = entry
            modelContext.insert(entry)

            entry.tags.append(generatedTag(modelContext: modelContext))
            if conversation.isProvocation {
                entry.tags.append(provocationTag(modelContext: modelContext))
            }
            if conversation.isAcquaintance {
                entry.tags.append(acquaintanceTag(modelContext: modelContext))
            }

            try? modelContext.save()

            if conversation.isAcquaintance {
                await updateAboutMe(from: history)
            }
            
            return entry
        } catch {
            endConversationErrors[conversation.id] = (error as? OllamaError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }
    
    private func updateAboutMe(from history: [ChatMessage]) async {
        let existingAboutMe = UserDefaults.standard.string(forKey: "aboutMe")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard let updated = try? await client.complete(
            messages: PromptBuilder.buildAboutMeMessages(existingAboutMe: existingAboutMe, history: history)
        ) else { return }

        let trimmed = String(updated.trimmingCharacters(in: .whitespacesAndNewlines).prefix(AppLimits.maxAboutMeLength))
        guard !trimmed.isEmpty else { return }

        UserDefaults.standard.set(trimmed, forKey: "aboutMe")
        UserDefaults.standard.set(true, forKey: "hasCompletedAcquaintance")
    }

    private func generatedTag(modelContext: ModelContext) -> JournalEntryTag {
        let descriptor = FetchDescriptor<JournalEntryTag>()
        if let allTags = try? modelContext.fetch(descriptor),
           let existing = allTags.first(where: { $0.name.caseInsensitiveCompare("Sariel") == .orderedSame }) {
            return existing
        }
        let tag = JournalEntryTag(name: "Sariel")
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
        reconcileSummary(for: conversation)
        try? modelContext.save()
    }

    func deleteMessages(after message: ChatMessage, in conversation: Conversation, modelContext: ModelContext) {
        let cutoff = message.timestamp
        let toRemove = conversation.messages.filter { $0.timestamp > cutoff }

        for msg in toRemove {
            conversation.messages.removeAll { $0.id == msg.id }
            modelContext.delete(msg)
        }
        reconcileSummary(for: conversation)
        try? modelContext.save()
    }

    private func reconcileSummary(for conversation: Conversation) {
        let remainingCount = conversation.messages.filter { $0.isValidExchange }.count
        if remainingCount < conversation.summarizedMessageCount {
            conversation.summarizedMessageCount = remainingCount
            conversation.summary = ""
        }
    }

    private func fetchJournalContextIfEnabled(modelContext: ModelContext) -> String {
        guard UserDefaults.standard.bool(forKey: "useJournalContext") else { return "" }

        var descriptor = FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = PromptBuilder.journalContextEntryCount

        guard let entries = try? modelContext.fetch(descriptor) else { return "" }
        return PromptBuilder.buildJournalContextText(entries: entries)
    }

    private func fetchCredibilityContextIfEnabled(modelContext: ModelContext) -> String {
        guard UserDefaults.standard.bool(forKey: "useCredibilityContext") else { return "" }

        let descriptor = FetchDescriptor<Commitment>(
            predicate: #Predicate<Commitment> { $0.status != "pending" },
            sortBy: [SortDescriptor(\.resolvedAt)]
        )

        guard let resolved = try? modelContext.fetch(descriptor) else { return "" }
        return PromptBuilder.buildCredibilityContextText(resolvedCommitments: resolved)
    }

    func fetchPendingCommitments(modelContext: ModelContext) -> [Commitment] {
        let descriptor = FetchDescriptor<Commitment>(
            predicate: #Predicate<Commitment> { $0.status == "pending" },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
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

    private func refreshSummaryIfNeeded(for conversation: Conversation, modelContext: ModelContext) async {
        let sortedMessages = conversation.messages
            .sorted { $0.timestamp < $1.timestamp }
            .filter { $0.isValidExchange }

        let unsummarizedCount = sortedMessages.count - conversation.summarizedMessageCount
        guard unsummarizedCount > PromptBuilder.summaryRefreshThreshold else { return }

        let newSummarizedCount = sortedMessages.count - PromptBuilder.keepRawMessages
        guard newSummarizedCount > conversation.summarizedMessageCount else { return }

        let messagesToIncorporate = Array(sortedMessages[conversation.summarizedMessageCount..<newSummarizedCount])
        guard !messagesToIncorporate.isEmpty else { return }

        do {
            let updatedSummary = try await client.complete(
                messages: PromptBuilder.buildSummaryMessages(existingSummary: conversation.summary, newMessages: messagesToIncorporate)
            )
            conversation.summary = updatedSummary.trimmingCharacters(in: .whitespacesAndNewlines)
            conversation.summarizedMessageCount = newSummarizedCount
            try? modelContext.save()
        } catch {

        }
    }
}
