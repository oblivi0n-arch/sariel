import Testing
@testable import sariel

struct CommitmentTests {

    @Test func recognizesEnglishDeclarationPrefix() {
        let result = Commitment.isDeclaration("I declare I will exercise every day this week")
        #expect(result == true)
    }

    @Test func recognizesPolishDeclarationPrefix() {
        let result = Commitment.isDeclaration("Ja deklaruję, że będę ćwiczyć codziennie w tym tygodniu")
        #expect(result == true)
    }

    @Test func isCaseInsensitive() {
        let result = Commitment.isDeclaration("I DECLARE something important")
        #expect(result == true)
    }

    @Test func trimsLeadingWhitespaceBeforeChecking() {
        let result = Commitment.isDeclaration("   i declare something important")
        #expect(result == true)
    }

    @Test func returnsFalseForOrdinaryMessage() {
        let result = Commitment.isDeclaration("I think I will try to exercise more")
        #expect(result == false)
    }

    @Test func returnsFalseForEmptyString() {
        let result = Commitment.isDeclaration("")
        #expect(result == false)
    }

    @Test func returnsFalseWhenPrefixIsMissingTheSpace() {
        let result = Commitment.isDeclaration("ideclare something")
        #expect(result == false)
    }
}
