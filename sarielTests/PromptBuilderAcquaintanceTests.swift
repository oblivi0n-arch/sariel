import Testing
@testable import sariel

struct PromptBuilderAcquaintanceTests {

    // Fixed two-message shape: system prompt followed by the instruction
    // that actually triggers generating the opening question.
    @Test func buildAcquaintanceMessagesReturnsSystemPromptAndOpeningInstruction() {
        let messages = PromptBuilder.buildAcquaintanceMessages()

        #expect(messages.count == 2)
        #expect(messages[0].role == "system")
        #expect(messages[0].content == PromptBuilder.acquaintanceSystemPrompt)
        #expect(messages[1].role == "user")
        #expect(messages[1].content == L10n.PromptAcquaintance.generateOpeningQuestionInstruction)
    }

    // The acquaintance question is passed through untouched as a plain user
    // message under the dedicated title system prompt.
    @Test func buildAcquaintanceTitleMessagesWrapsQuestionAsUserMessage() {
        let messages = PromptBuilder.buildAcquaintanceTitleMessages(question: "QUESTION_MARKER")

        #expect(messages.count == 2)
        #expect(messages[0].role == "system")
        #expect(messages[1].role == "user")
        #expect(messages[1].content == "QUESTION_MARKER")
    }

    // No existing profile: only the system prompt and the final
    // transcript+instruction message should be present.
    @Test func buildAboutMeMessagesOmitsExistingProfileMessageWhenEmpty() {
        let messages = PromptBuilder.buildAboutMeMessages(existingAboutMe: "", history: [])

        #expect(messages.count == 2)
        #expect(messages[1].content.contains(L10n.PromptAcquaintance.conversationIntro))
    }

    // An existing profile must appear as its own dedicated message, so the
    // model can merge it with the new conversation instead of starting over.
    @Test func buildAboutMeMessagesIncludesExistingProfileMessageWhenProvided() {
        let messages = PromptBuilder.buildAboutMeMessages(existingAboutMe: "EXISTING_MARKER", history: [])

        #expect(messages.count == 3)
        #expect(messages[1].role == "user")
        #expect(messages[1].content.contains("EXISTING_MARKER"))
    }

    // The conversation transcript must label each line by speaker
    // ("User:" / "Sariel:"), not by the raw internal role string.
    @Test func buildAboutMeMessagesFormatsTranscriptWithSpeakerLabels() {
        let history = [
            ChatMessage(role: .user, content: "USER_MARKER"),
            ChatMessage(role: .guide, content: "GUIDE_MARKER")
        ]

        let messages = PromptBuilder.buildAboutMeMessages(existingAboutMe: "", history: history)
        let transcriptMessage = messages.last?.content ?? ""

        #expect(transcriptMessage.contains("User: USER_MARKER"))
        #expect(transcriptMessage.contains("Sariel: GUIDE_MARKER"))
    }
}
