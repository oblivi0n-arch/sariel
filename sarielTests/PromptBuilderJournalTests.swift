import Testing
@testable import sariel

struct PromptBuilderJournalTests {

    // No summary provided: the summary line should be skipped entirely,
    // and history messages should keep their original order and role mapping.
    @Test func buildJournalMessagesWithoutSummaryOmitsSummaryMessage() {
        let history = [
            ChatMessage(role: .user, content: "USER_MARKER"),
            ChatMessage(role: .guide, content: "GUIDE_MARKER")
        ]

        let messages = PromptBuilder.buildJournalMessages(history: history, style: .conciseFactual)

        #expect(messages.count == 4)
        #expect(messages[0].role == "system")
        #expect(messages[1].role == "user")
        #expect(messages[1].content == "USER_MARKER")
        #expect(messages[2].role == "assistant")
        #expect(messages[2].content == "GUIDE_MARKER")
        #expect(messages[3].role == "user")
    }

    // Summary provided: it must appear as its own message right after the
    // system prompt, even when there's no conversation history at all.
    @Test func buildJournalMessagesWithSummaryInsertsSummaryMessage() {
        let messages = PromptBuilder.buildJournalMessages(history: [], summary: "SUMMARY_MARKER", style: .conciseFactual)

        #expect(messages.count == 3)
        #expect(messages[1].role == "user")
        #expect(messages[1].content.contains("SUMMARY_MARKER"))
    }

    // Regardless of history/summary, the very last message must be the
    // "write it now" instruction — this is what actually triggers generation.
    @Test func buildJournalMessagesEndsWithWriteJournalNowInstruction() {
        let messages = PromptBuilder.buildJournalMessages(history: [], style: .conciseFactual)

        #expect(messages.last?.role == "user")
        #expect(messages.last?.content == L10n.PromptJournal.writeJournalNowInstruction)
    }

    // The three journal styles must produce genuinely different system
    // prompts — otherwise the style picker in Settings would be a no-op.
    @Test func journalSystemPromptDiffersAcrossAllThreeStyles() {
        let concise = PromptBuilder.journalSystemPrompt(for: .conciseFactual)
        let extendedFactual = PromptBuilder.journalSystemPrompt(for: .extendedFactual)
        let extendedNarrative = PromptBuilder.journalSystemPrompt(for: .extendedNarrative)

        #expect(concise != extendedFactual)
        #expect(concise != extendedNarrative)
        #expect(extendedFactual != extendedNarrative)
    }

    // buildJournalTitleMessages should just wrap the finished entry content
    // as a plain user message under the dedicated title system prompt.
    @Test func buildJournalTitleMessagesWrapsEntryContentAsUserMessage() {
        let messages = PromptBuilder.buildJournalTitleMessages(entryContent: "ENTRY_MARKER")

        #expect(messages.count == 2)
        #expect(messages[0].role == "system")
        #expect(messages[1].role == "user")
        #expect(messages[1].content == "ENTRY_MARKER")
    }
}
