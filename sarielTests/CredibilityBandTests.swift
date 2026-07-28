import Testing
@testable import sariel

struct CredibilityBandTests {
    private func makeCommitments(fulfilled: Int, broken: Int, pending: Int = 0) -> [Commitment] {
        var result: [Commitment] = []

        for _ in 0..<fulfilled {
            let commitment = Commitment(declarationText: "test", failureMeaning: "test")
            commitment.commitmentStatus = .fulfilled
            result.append(commitment)
        }
        for _ in 0..<broken {
            let commitment = Commitment(declarationText: "test", failureMeaning: "test")
            commitment.commitmentStatus = .broken
            result.append(commitment)
        }
        for _ in 0..<pending {
            result.append(Commitment(declarationText: "test", failureMeaning: "test"))
        }

        return result
    }

    @Test func fewerThanThreeResolvedIsInsufficientData() {
        let commitments = makeCommitments(fulfilled: 1, broken: 1)
        #expect(CredibilityBand.evaluate(from: commitments) == .insufficientData)
        #expect(CredibilityBand.percentage(from: commitments) == nil)
    }

    @Test func pendingCommitmentsDoNotCountTowardSampleMinimum() {
        let commitments = makeCommitments(fulfilled: 1, broken: 1, pending: 5)
        #expect(CredibilityBand.evaluate(from: commitments) == .insufficientData)
    }

    @Test func zeroPercentFulfilledIsPoor() {
        let commitments = makeCommitments(fulfilled: 0, broken: 3)
        #expect(CredibilityBand.evaluate(from: commitments) == .poor)
        #expect(CredibilityBand.percentage(from: commitments) == 0)
    }

    @Test func justBelow40PercentIsPoor() {
        let commitments = makeCommitments(fulfilled: 3, broken: 7)
        #expect(CredibilityBand.evaluate(from: commitments) == .poor)
    }

    @Test func exactly40PercentIsMixed() {
        let commitments = makeCommitments(fulfilled: 4, broken: 6)
        #expect(CredibilityBand.evaluate(from: commitments) == .mixed)
    }

    @Test func justBelow70PercentIsMixed() {
        let commitments = makeCommitments(fulfilled: 6, broken: 4)
        #expect(CredibilityBand.evaluate(from: commitments) == .mixed)
    }

    @Test func exactly70PercentIsSolid() {
        let commitments = makeCommitments(fulfilled: 7, broken: 3)
        #expect(CredibilityBand.evaluate(from: commitments) == .solid)
    }

    @Test func hundredPercentIsSolid() {
        let commitments = makeCommitments(fulfilled: 5, broken: 0)
        #expect(CredibilityBand.evaluate(from: commitments) == .solid)
        #expect(CredibilityBand.percentage(from: commitments) == 100)
    }
}
