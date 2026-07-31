import Testing
@testable import sariel

struct PromptBuilderTests {

    @Test func buildMessagesWithNoOptionalsProducesOnlySystemPrompt() {
        let messages = PromptBuilder.buildMessages(history: [])
        #expect(messages.count == 1)
        #expect(messages[0].role == "system")
    }

    @Test func buildMessagesIncludesAllSectionsInCorrectOrderWhenProvided() {
        let history = [
            ChatMessage(role: .user, content: "user message"),
            ChatMessage(role: .guide, content: "guide reply")
        ]

        let messages = PromptBuilder.buildMessages(
            history: history,
            summary: "SUMMARY_MARKER",
            journalContext: "JOURNAL_MARKER",
            credibilityContext: "CREDIBILITY_MARKER",
            username: "Kuba"
        )

        #expect(messages.count == 7)
        #expect(messages[1].content.contains("Kuba"))
        #expect(messages[2].content.contains("JOURNAL_MARKER"))
        #expect(messages[3].content.contains("CREDIBILITY_MARKER"))
        #expect(messages[4].content.contains("SUMMARY_MARKER"))
        #expect(messages[5].role == "user")
        #expect(messages[6].role == "assistant")
    }

    @Test func historyIsTrimmedToMaxHistoryMessagesWhenNoSummary() {
        let history = (0..<35).map { ChatMessage(role: .user, content: "message \($0)") }
        let messages = PromptBuilder.buildMessages(history: history)

        let historyMessages = messages.suffix(PromptBuilder.maxHistoryMessages)
        #expect(historyMessages.count == PromptBuilder.maxHistoryMessages)
        #expect(historyMessages.first?.content == "message 5")
    }

    @Test func historyIsTrimmedToKeepRawMessagesWhenSummaryIsPresent() {
        let history = (0..<10).map { ChatMessage(role: .user, content: "message \($0)") }
        let messages = PromptBuilder.buildMessages(history: history, summary: "some summary")

        let historyMessages = messages.suffix(PromptBuilder.keepRawMessages)
        #expect(historyMessages.count == PromptBuilder.keepRawMessages)
        #expect(historyMessages.first?.content == "message 2")
    }


    @Test func verdictMessagesIncludeSkippedNoticeWhenFailureMeaningIsEmpty() {
        let commitment = Commitment(declarationText: "I declare I will run every day", failureMeaning: "")
        let messages = PromptBuilder.buildVerdictMessages(commitment: commitment, history: [])

        #expect(messages.count == 4)
        #expect(messages[1].content.contains("I declare I will run every day"))
        switch L10n.lang {
        case .en:
            #expect(messages[2].content.contains("chose not to answer"))
        case .pl:
            #expect(messages[2].content.contains("zdecydował się nie odpowiadać"))
        }
    }

    @Test func verdictMessagesIncludeFailureMeaningContextWhenPresent() {
        let commitment = Commitment(
            declarationText: "I declare I will run every day",
            failureMeaning: "FAILURE_MEANING_MARKER"
        )
        let messages = PromptBuilder.buildVerdictMessages(commitment: commitment, history: [])

        #expect(messages.count == 4)
        #expect(messages[2].content.contains("FAILURE_MEANING_MARKER"))
    }

    @Test func titlePromptWithoutExtraRuleNumbersFinalRuleAsThree() {
        let prompt = PromptBuilder.titleSystemPrompt
        switch L10n.lang {
        case .en:
            #expect(prompt.contains("3. Respond with ONLY the title, nothing else."))
        case .pl:
            #expect(prompt.contains("3. Odpowiedz TYLKO tytułem, niczym więcej."))
        }
        #expect(!prompt.contains("4. "))
    }

    @Test func provocationTitlePromptInsertsExtraRuleAndShiftsFinalRuleToFour() {
        let prompt = PromptBuilder.provocationTitleSystemPrompt
        switch L10n.lang {
        case .en:
            #expect(prompt.contains("3. Do not phrase it as a question."))
            #expect(prompt.contains("4. Respond with ONLY the title, nothing else."))
        case .pl:
            #expect(prompt.contains("3. Nie formułuj go jako pytania."))
            #expect(prompt.contains("4. Odpowiedz TYLKO tytułem, niczym więcej."))
        }
    }
}
