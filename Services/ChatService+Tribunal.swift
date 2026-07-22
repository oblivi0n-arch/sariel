import Foundation
import SwiftData

extension ChatService {
    func startTribunal(modelContext: ModelContext) async -> Conversation? {
        if let existing = fetchInProgressTribunal(modelContext: modelContext) {
            return existing
        }

        let pending = fetchPendingCommitments(modelContext: modelContext)
        guard !pending.isEmpty else { return nil }

        let sessionNumber = fetchTribunalSessionCount(modelContext: modelContext) + 1
        let dateString = Date().formatted(date: .abbreviated, time: .omitted)
        let conversation = Conversation(title: "Tribunal — session \(sessionNumber) — \(dateString)")
        conversation.isTribunal = true
        modelContext.insert(conversation)

        let guideMessage = ChatMessage(role: .guide, content: "")
        guideMessage.conversation = conversation
        conversation.messages.append(guideMessage)
        modelContext.insert(guideMessage)
        try? modelContext.save()

        await runTribunalOpening(into: guideMessage, for: conversation, modelContext: modelContext)

        return conversation
    }

    func retryTribunalOpening(for conversation: Conversation, modelContext: ModelContext) async {
        let sorted = conversation.messages.sorted { $0.timestamp < $1.timestamp }
        guard let guideMessage = sorted.first, guideMessage.messageRole == .guide else { return }
        guideMessage.content = ""

        await runTribunalOpening(into: guideMessage, for: conversation, modelContext: modelContext)
    }

    func runTribunalOpening(into guideMessage: ChatMessage, for conversation: Conversation, modelContext: ModelContext) async {
        let pending = fetchPendingCommitments(modelContext: modelContext)

        generatingConversationIDs.insert(conversation.id)
        lastErrors[conversation.id] = nil

        do {
            for try await chunk in client.streamChat(messages: PromptBuilder.buildTribunalOpeningMessages(commitments: pending)) {
                guideMessage.content += chunk
            }
        } catch {
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

        generatingConversationIDs.remove(conversation.id)
        try? modelContext.save()
    }
    
    func generateVerdicts(for conversation: Conversation, modelContext: ModelContext) async -> [TribunalVerdict] {
        guard conversation.isTribunal else { return [] }
        let pending = fetchPendingCommitments(modelContext: modelContext)
        guard !pending.isEmpty else { return [] }

        isGeneratingVerdicts.insert(conversation.id)
        verdictErrors[conversation.id] = nil
        defer { isGeneratingVerdicts.remove(conversation.id) }

        let history = conversation.messages
            .sorted { $0.timestamp < $1.timestamp }
            .filter { $0.isValidExchange }

        var verdicts: [TribunalVerdict] = []
        var failedCount = 0

        for commitment in pending {
            guard let response = try? await client.complete(
                messages: PromptBuilder.buildVerdictMessages(commitment: commitment, history: history)
            ) else {
                failedCount += 1
                continue
            }

            let (status, reasoning) = parseVerdict(response)
            verdicts.append(TribunalVerdict(commitment: commitment, proposedStatus: status, reasoning: reasoning))
        }

        if failedCount > 0 {
            verdictErrors[conversation.id] = "Could not reach Ollama for \(failedCount) of \(pending.count) commitment\(pending.count == 1 ? "" : "s")."
        }

        return verdicts
    }

    func parseVerdict(_ text: String) -> (CommitmentStatus, String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)

        let firstLine = lines.first?.uppercased() ?? ""
        // TODO: This falls back to `.broken` whenever "FULFILLED" isn't found in the first
        // line — but that also silently catches malformed/unrecognized model output (e.g.
        // truncated response, model didn't follow the format), not just a genuine BROKEN
        // judgment. Should detect FULFILLED and BROKEN as two distinct keywords, treat
        // "neither found" as a separate `unrecognized` case, and retry the Ollama request
        // a bounded number of times (e.g. 2 attempts total) before falling back to
        // failedCount/verdictErrors, same as the existing network-failure path below.
        let status: CommitmentStatus = firstLine.contains("FULFILLED") ? .fulfilled : .broken
        let reasoning = lines.count > 1 ? String(lines[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""

        return (status, reasoning)
    }

    func applyVerdicts(_ verdicts: [TribunalVerdict], for conversation: Conversation, modelContext: ModelContext) {
        for verdict in verdicts {
            verdict.commitment.commitmentStatus = verdict.proposedStatus
            verdict.commitment.resolvedAt = Date()
            verdict.commitment.verdictReasoning = verdict.reasoning
            verdict.commitment.resolvingConversation = conversation
        }
        conversation.tribunalResolvedAt = Date()
        try? modelContext.save()
    }

    func fetchPendingCommitments(modelContext: ModelContext) -> [Commitment] {
        let descriptor = FetchDescriptor<Commitment>(
            predicate: #Predicate<Commitment> { $0.status == "pending" },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchInProgressTribunal(modelContext: ModelContext) -> Conversation? {
        let descriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate<Conversation> { $0.isTribunal && $0.tribunalResolvedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor))?.first
    }
    
    func fetchTribunalSessionCount(modelContext: ModelContext) -> Int {
        let descriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate<Conversation> { $0.isTribunal }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
