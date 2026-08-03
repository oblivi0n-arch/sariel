import Testing
@testable import sariel

struct PromptBuilderCredibilityTests {

    // Fewer than CredibilityBand.sampleMinimum resolved commitments: there's
    // nothing meaningful to tell the model yet, so context must be empty.
    @Test func buildCredibilityContextTextReturnsEmptyStringWhenDataIsInsufficient() {
        let commitments = (0..<2).map { offset -> Commitment in
            let commitment = Commitment(declarationText: "d\(offset)", failureMeaning: "f")
            commitment.commitmentStatus = .fulfilled
            return commitment
        }

        let result = PromptBuilder.buildCredibilityContextText(resolvedCommitments: commitments)
        #expect(result == "")
    }

    // Once there's enough resolved data, the credibility band's
    // human-readable description must appear in the summary line.
    @Test func buildCredibilityContextTextIncludesBandDescriptionWhenDataIsSufficient() {
        let commitments = (0..<3).map { offset -> Commitment in
            let commitment = Commitment(declarationText: "d\(offset)", failureMeaning: "f")
            commitment.commitmentStatus = .fulfilled
            return commitment
        }

        let result = PromptBuilder.buildCredibilityContextText(resolvedCommitments: commitments)
        #expect(result.contains("solid"))
    }

    // Each resolved commitment must appear as its own line: a FULFILLED/BROKEN
    // verdict word, the declaration text, and the recorded verdict reasoning.
    @Test func buildCredibilityContextTextListsEachCommitmentWithItsVerdictAndReasoning() {
        let fulfilledOne = Commitment(declarationText: "DECLARATION_MARKER", failureMeaning: "f")
        fulfilledOne.commitmentStatus = .fulfilled
        fulfilledOne.verdictReasoning = "REASON_MARKER"

        let brokenFillers = (0..<2).map { offset -> Commitment in
            let commitment = Commitment(declarationText: "filler\(offset)", failureMeaning: "f")
            commitment.commitmentStatus = .broken
            return commitment
        }

        let result = PromptBuilder.buildCredibilityContextText(resolvedCommitments: [fulfilledOne] + brokenFillers)

        #expect(result.contains("FULFILLED"))
        #expect(result.contains("DECLARATION_MARKER"))
        #expect(result.contains("REASON_MARKER"))
        #expect(result.contains("BROKEN"))
    }
}
