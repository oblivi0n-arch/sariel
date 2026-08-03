import Testing
import Foundation
@testable import sariel

struct PromptBuilderTribunalTests {

    // No pending commitments: context text must be empty, so the caller
    // knows to skip the "pending declarations" message entirely.
    @Test func buildTribunalContextTextReturnsEmptyStringForNoCommitments() {
        let result = PromptBuilder.buildTribunalContextText(commitments: [])
        #expect(result == "")
    }

    // Each commitment becomes its own numbered line, in the order given —
    // the Tribunal relies on this numbering to reference declarations 1:1.
    @Test func buildTribunalContextTextNumbersEachDeclarationInOrder() {
        let commitments = [
            Commitment(declarationText: "first declaration", failureMeaning: "f"),
            Commitment(declarationText: "second declaration", failureMeaning: "f")
        ]

        let result = PromptBuilder.buildTribunalContextText(commitments: commitments)
        let lines = result.components(separatedBy: "\n")

        #expect(lines.count == 2)
        #expect(lines[0].hasPrefix("1."))
        #expect(lines[0].contains("first declaration"))
        #expect(lines[1].hasPrefix("2."))
        #expect(lines[1].contains("second declaration"))
    }

    // With no pending commitments, buildTribunalMessages should not insert
    // an empty/pointless "pending declarations" system message.
    @Test func buildTribunalMessagesOmitsPendingDeclarationsMessageWhenThereAreNoCommitments() {
        let messages = PromptBuilder.buildTribunalMessages(history: [], commitments: [])

        #expect(messages.count == 1)
        #expect(messages[0].role == "system")
    }

    // Pending commitments must surface as a dedicated system message right
    // after the main tribunal system prompt.
    @Test func buildTribunalMessagesIncludesPendingDeclarationsMessageWhenCommitmentsExist() {
        let commitment = Commitment(declarationText: "DECLARATION_MARKER", failureMeaning: "f")
        let messages = PromptBuilder.buildTribunalMessages(history: [], commitments: [commitment])

        #expect(messages.count == 2)
        #expect(messages[1].role == "system")
        #expect(messages[1].content.contains("DECLARATION_MARKER"))
    }

    // A non-empty summary must appear as its own system message, on top of
    // (or instead of) the pending-declarations message.
    @Test func buildTribunalMessagesIncludesSummaryMessageWhenProvided() {
        let messages = PromptBuilder.buildTribunalMessages(history: [], commitments: [], summary: "SUMMARY_MARKER")

        #expect(messages.count == 2)
        #expect(messages[1].role == "system")
        #expect(messages[1].content.contains("SUMMARY_MARKER"))
    }

    // History messages must map ChatMessage's .user/.guide roles to Ollama's
    // "user"/"assistant" roles, appended after any context/summary messages.
    @Test func buildTribunalMessagesMapsHistoryRolesCorrectly() {
        let history = [
            ChatMessage(role: .user, content: "USER_MARKER"),
            ChatMessage(role: .guide, content: "GUIDE_MARKER")
        ]

        let messages = PromptBuilder.buildTribunalMessages(history: history, commitments: [])

        #expect(messages.count == 3)
        #expect(messages[1].role == "user")
        #expect(messages[1].content == "USER_MARKER")
        #expect(messages[2].role == "assistant")
        #expect(messages[2].content == "GUIDE_MARKER")
    }

    // Opening messages are just the standard tribunal messages plus one
    // final "open the session now" user instruction appended at the end.
    @Test func buildTribunalOpeningMessagesAppendsOpenSessionInstruction() {
        let messages = PromptBuilder.buildTribunalOpeningMessages(commitments: [])

        #expect(messages.count == 2)
        #expect(messages.last?.role == "user")
        #expect(messages.last?.content == L10n.PromptTribunal.openSessionInstruction)
    }

    // Extends the existing buildVerdictMessages coverage: history exchanged
    // during the tribunal must be role-mapped and placed before the final
    // "deliver your verdict" instruction.
    @Test func buildVerdictMessagesMapsHistoryRolesAndEndsWithDeliverInstruction() {
        let commitment = Commitment(declarationText: "DECLARATION_MARKER", failureMeaning: "f")
        let history = [
            ChatMessage(role: .user, content: "USER_MARKER"),
            ChatMessage(role: .guide, content: "GUIDE_MARKER")
        ]

        let messages = PromptBuilder.buildVerdictMessages(commitment: commitment, history: history)

        #expect(messages.count == 6)
        #expect(messages[3].role == "user")
        #expect(messages[3].content == "USER_MARKER")
        #expect(messages[4].role == "assistant")
        #expect(messages[4].content == "GUIDE_MARKER")
        #expect(messages.last?.role == "user")
        #expect(messages.last?.content == L10n.PromptTribunal.deliverVerdictInstruction("DECLARATION_MARKER"))
    }
}
