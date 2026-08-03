import Testing
@testable import sariel

struct PromptBuilderProvocationTests {

    // Fixed two-message shape: system prompt followed by the instruction
    // that actually triggers generating the opening question.
    @Test func buildProvocationMessagesReturnsSystemPromptAndOpeningInstruction() {
        let messages = PromptBuilder.buildProvocationMessages()

        #expect(messages.count == 2)
        #expect(messages[0].role == "system")
        #expect(messages[0].content == PromptBuilder.provocationSystemPrompt)
        #expect(messages[1].role == "user")
        #expect(messages[1].content == L10n.PromptProvocation.generateOpeningQuestionInstruction)
    }

    // The provocation question is passed through untouched as a plain user
    // message under the dedicated title system prompt.
    @Test func buildProvocationTitleMessagesWrapsQuestionAsUserMessage() {
        let messages = PromptBuilder.buildProvocationTitleMessages(question: "QUESTION_MARKER")

        #expect(messages.count == 2)
        #expect(messages[0].role == "system")
        #expect(messages[1].role == "user")
        #expect(messages[1].content == "QUESTION_MARKER")
    }
}
