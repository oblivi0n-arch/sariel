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
        let conversation = Conversation(title: L10n.TribunalSession.sessionTitle(sessionNumber: sessionNumber, date: Date()))
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

        let maxVerdictParseAttempts = 2

        for commitment in pending {
            var resolvedVerdict: TribunalVerdict?

            attempts: for _ in 1...maxVerdictParseAttempts {
                guard let response = try? await client.complete(
                    messages: PromptBuilder.buildVerdictMessages(commitment: commitment, history: history),
                ) else {
                    break attempts
                }

                switch parseVerdict(response) {
                case .fulfilled(let reasoning):
                    resolvedVerdict = TribunalVerdict(commitment: commitment, proposedStatus: .fulfilled, reasoning: reasoning)
                    break attempts
                case .broken(let reasoning):
                    resolvedVerdict = TribunalVerdict(commitment: commitment, proposedStatus: .broken, reasoning: reasoning)
                    break attempts
                case .unrecognized:
                    continue attempts
                }
            }

            if let resolvedVerdict {
                verdicts.append(resolvedVerdict)
            } else {
                failedCount += 1
            }
        }

        if failedCount > 0 {
            verdictErrors[conversation.id] = L10n.TribunalSession.verdictError(failedCount: failedCount, total: pending.count)
        }

        return verdicts
    }

    enum VerdictParseResult: Equatable {
        case fulfilled(reasoning: String)
        case broken(reasoning: String)
        case unrecognized
    }

    func parseVerdict(_ text: String) -> VerdictParseResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)

        let firstLine = lines.first?.uppercased() ?? ""
        let reasoning = lines.count > 1 ? String(lines[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""

        if firstLine.contains("FULFILLED") {
            return .fulfilled(reasoning: reasoning)
        } else if firstLine.contains("BROKEN") {
            return .broken(reasoning: reasoning)
        } else {
            return .unrecognized
        }
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

extension L10n {
    enum TribunalSession {
        static func sessionTitle(sessionNumber: Int, date: Date) -> String {
            switch lang {
            case .en:
                let dateString = date.formatted(date: .abbreviated, time: .omitted)
                return "Tribunal – session \(sessionNumber) – \(dateString)"
            case .pl:
                let dateString = date.formatted(
                    .dateTime.day().month(.abbreviated).year()
                    .locale(LanguageManager.shared.locale)
                )
                return "Trybunał – sesja \(sessionNumber) – \(dateString)"
            }
        }
        
        static func verdictError(failedCount: Int, total: Int) -> String {
            switch lang {
            case .en: return "Could not get a valid verdict for \(failedCount) of \(total) commitment\(total == 1 ? "" : "s")."
            case .pl:
                let noun = total == 1 ? "Zobowiązania" : "Zobowiązań"
                return "Nie udało się uzyskać poprawnego wyroku dla \(failedCount) z \(total) \(noun)."
            }
        }
    }
}
