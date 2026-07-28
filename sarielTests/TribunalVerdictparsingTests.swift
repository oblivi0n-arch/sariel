import Testing
@testable import sariel

struct TribunalVerdictParsingTests {

    @Test @MainActor
    func recognizesFulfilledKeyword() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("FULFILLED\nUser followed through completely.")
        #expect(result == .fulfilled(reasoning: "User followed through completely."))
    }

    @Test @MainActor
    func recognizesBrokenKeyword() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("BROKEN\nUser gave vague excuses.")
        #expect(result == .broken(reasoning: "User gave vague excuses."))
    }

    @Test @MainActor
    func keywordMatchingIsCaseInsensitive() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("fulfilled\nGreat, concrete follow-through.")
        #expect(result == .fulfilled(reasoning: "Great, concrete follow-through."))
    }

    @Test @MainActor
    func returnsUnrecognizedWhenNeitherKeywordIsPresent() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("The user seems to have done something about it.")
        #expect(result == .unrecognized)
    }

    @Test @MainActor
    func returnsUnrecognizedForEmptyResponse() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("")
        #expect(result == .unrecognized)
    }

    @Test @MainActor
    func reasoningIsTrimmedOfSurroundingWhitespace() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("BROKEN\n   spaces around this reasoning   ")
        #expect(result == .broken(reasoning: "spaces around this reasoning"))
    }

    @Test @MainActor
    func missingSecondLineProducesEmptyReasoning() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("FULFILLED")
        #expect(result == .fulfilled(reasoning: ""))
    }

    @Test @MainActor
    func fulfilledTakesPriorityWhenBothKeywordsAppearOnFirstLine() {
        let chatService = ChatService()
        let result = chatService.parseVerdict("FULFILLED BROKEN\nambiguous line from the model")
        #expect(result == .fulfilled(reasoning: "ambiguous line from the model"))
    }
}
