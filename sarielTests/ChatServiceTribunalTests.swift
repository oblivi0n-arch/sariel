import Testing
import SwiftData
import Foundation
@testable import sariel

struct ChatServiceTribunalTests {

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([
            Conversation.self,
            ChatMessage.self,
            Commitment.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return ModelContext(container)
    }

    // MARK: - parseVerdict

    // "FULFILLED" on the first line, with a second line of reasoning.
    @Test @MainActor
    func recognizesFulfilledKeyword() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("FULFILLED\nUser followed through completely.")
        #expect(result == .fulfilled(reasoning: "User followed through completely."))
    }

    // "BROKEN" on the first line, with a second line of reasoning.
    @Test @MainActor
    func recognizesBrokenKeyword() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("BROKEN\nUser gave vague excuses.")
        #expect(result == .broken(reasoning: "User gave vague excuses."))
    }

    // Keyword detection must not care about letter casing from the model's output.
    @Test @MainActor
    func keywordMatchingIsCaseInsensitive() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("fulfilled\nGreat, concrete follow-through.")
        #expect(result == .fulfilled(reasoning: "Great, concrete follow-through."))
    }

    // Neither keyword present: the response can't be trusted, so it's unrecognized.
    @Test @MainActor
    func returnsUnrecognizedWhenNeitherKeywordIsPresent() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("The user seems to have done something about it.")
        #expect(result == .unrecognized)
    }

    // An empty model response is just as invalid as a wrong one.
    @Test @MainActor
    func returnsUnrecognizedForEmptyResponse() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("")
        #expect(result == .unrecognized)
    }

    // Reasoning should never carry stray leading/trailing whitespace into the UI.
    @Test @MainActor
    func reasoningIsTrimmedOfSurroundingWhitespace() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("BROKEN\n   spaces around this reasoning   ")
        #expect(result == .broken(reasoning: "spaces around this reasoning"))
    }

    // A one-line response (no reasoning line at all) should not crash — just empty reasoning.
    @Test @MainActor
    func missingSecondLineProducesEmptyReasoning() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("FULFILLED")
        #expect(result == .fulfilled(reasoning: ""))
    }

    // If the model contradicts itself on the first line, FULFILLED wins the tie-break.
    @Test @MainActor
    func fulfilledTakesPriorityWhenBothKeywordsAppearOnFirstLine() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("FULFILLED BROKEN\nambiguous line from the model")
        #expect(result == .fulfilled(reasoning: "ambiguous line from the model"))
    }

    // MARK: - fetchInProgressTribunal

    // No tribunal conversations at all: nothing to resume.
    @Test @MainActor
    func fetchInProgressTribunalReturnsNilWhenNoneExist() throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()

        let ordinaryConversation = Conversation()
        context.insert(ordinaryConversation)
        try context.save()

        let result = chatService.fetchInProgressTribunal(modelContext: context)
        #expect(result == nil)
    }

    // A tribunal with no tribunalResolvedAt is, by definition, still in progress.
    @Test @MainActor
    func fetchInProgressTribunalReturnsUnresolvedTribunal() throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()

        let tribunal = Conversation()
        tribunal.isTribunal = true
        context.insert(tribunal)
        try context.save()

        let result = chatService.fetchInProgressTribunal(modelContext: context)
        #expect(result?.id == tribunal.id)
    }

    // A tribunal that has already received a verdict must not be resumed again.
    @Test @MainActor
    func fetchInProgressTribunalIgnoresResolvedTribunal() throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()

        let resolvedTribunal = Conversation()
        resolvedTribunal.isTribunal = true
        resolvedTribunal.tribunalResolvedAt = Date()
        context.insert(resolvedTribunal)
        try context.save()

        let result = chatService.fetchInProgressTribunal(modelContext: context)
        #expect(result == nil)
    }

    // If several unresolved tribunals somehow exist, the most recently started one wins.
    @Test @MainActor
    func fetchInProgressTribunalReturnsMostRecentWhenMultipleExist() throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()

        let older = Conversation()
        older.isTribunal = true
        older.startedAt = Date().addingTimeInterval(-3600)

        let newer = Conversation()
        newer.isTribunal = true
        newer.startedAt = Date()

        context.insert(older)
        context.insert(newer)
        try context.save()

        let result = chatService.fetchInProgressTribunal(modelContext: context)
        #expect(result?.id == newer.id)
    }

    // MARK: - fetchTribunalSessionCount

    // Only conversations flagged isTribunal should count toward the next session number.
    @Test @MainActor
    func fetchTribunalSessionCountCountsOnlyTribunalConversations() throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()

        let tribunalOne = Conversation()
        tribunalOne.isTribunal = true
        let tribunalTwo = Conversation()
        tribunalTwo.isTribunal = true
        let ordinaryConversation = Conversation()

        [tribunalOne, tribunalTwo, ordinaryConversation].forEach { context.insert($0) }
        try context.save()

        #expect(chatService.fetchTribunalSessionCount(modelContext: context) == 2)
    }

    // No tribunal conversations yet: the next session should be numbered from zero.
    @Test @MainActor
    func fetchTribunalSessionCountReturnsZeroWhenNoneExist() throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()

        #expect(chatService.fetchTribunalSessionCount(modelContext: context) == 0)
    }

    // MARK: - applyVerdicts

    // Applying a verdict must stamp the judged commitment with its new status,
    // the reasoning behind it, a resolution date, and a link back to this conversation.
    @Test @MainActor
    func applyVerdictsUpdatesTheJudgedCommitment() throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()

        let conversation = Conversation()
        conversation.isTribunal = true
        let commitment = Commitment(declarationText: "d", failureMeaning: "f")
        context.insert(conversation)
        context.insert(commitment)
        try context.save()

        let verdict = TribunalVerdict(commitment: commitment, proposedStatus: .broken, reasoning: "REASON_MARKER")
        chatService.applyVerdicts([verdict], for: conversation, modelContext: context)

        #expect(commitment.commitmentStatus == .broken)
        #expect(commitment.verdictReasoning == "REASON_MARKER")
        #expect(commitment.resolvedAt != nil)
        #expect(commitment.resolvingConversation?.id == conversation.id)
    }

    // The conversation itself must be marked resolved even if there ended up
    // being zero verdicts to apply (e.g. every commitment failed to parse).
    @Test @MainActor
    func applyVerdictsMarksConversationAsResolvedEvenWithNoVerdicts() throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()

        let conversation = Conversation()
        conversation.isTribunal = true
        context.insert(conversation)
        try context.save()

        #expect(conversation.tribunalResolvedAt == nil)
        chatService.applyVerdicts([], for: conversation, modelContext: context)
        #expect(conversation.tribunalResolvedAt != nil)
    }

    // MARK: - generateVerdicts (guard clauses only — these return before any network call)

    // A non-tribunal conversation should never produce verdicts, no matter what's pending.
    @Test @MainActor
    func generateVerdictsReturnsEmptyForNonTribunalConversation() async throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()

        let conversation = Conversation()
        conversation.isTribunal = false
        context.insert(conversation)
        context.insert(Commitment(declarationText: "d", failureMeaning: "f"))
        try context.save()

        let verdicts = await chatService.generateVerdicts(for: conversation, modelContext: context)
        #expect(verdicts.isEmpty)
    }

    // With nothing pending to judge, there's nothing to send to the model at all.
    @Test @MainActor
    func generateVerdictsReturnsEmptyWhenThereAreNoPendingCommitments() async throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()

        let conversation = Conversation()
        conversation.isTribunal = true
        context.insert(conversation)
        try context.save()

        let verdicts = await chatService.generateVerdicts(for: conversation, modelContext: context)
        #expect(verdicts.isEmpty)
    }

    // MARK: - startTribunal (guard clauses only — these return before any network call)

    // With no pending declarations to put on trial, there's no session to start.
    @Test @MainActor
    func startTribunalReturnsNilWhenThereAreNoPendingCommitments() async throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()

        let result = await chatService.startTribunal(modelContext: context)
        #expect(result == nil)
    }

    // If a tribunal is already in progress, starting again must resume that
    // same session instead of silently creating a duplicate one.
    @Test @MainActor
    func startTribunalReturnsExistingInProgressTribunalWithoutCreatingANewOne() async throws {
        let context = try makeInMemoryContext()
        let chatService = ChatService()

        let existingTribunal = Conversation()
        existingTribunal.isTribunal = true
        context.insert(existingTribunal)
        try context.save()

        let result = await chatService.startTribunal(modelContext: context)

        #expect(result?.id == existingTribunal.id)
        let allTribunals = try context.fetch(
            FetchDescriptor<Conversation>(predicate: #Predicate<Conversation> { $0.isTribunal })
        )
        #expect(allTribunals.count == 1)
    }
}
