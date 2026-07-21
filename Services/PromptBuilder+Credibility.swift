import Foundation

extension PromptBuilder {
    static func buildCredibilityContextText(resolvedCommitments: [Commitment]) -> String {
        let band = Commitment.credibilityBand(from: resolvedCommitments)
        guard band != .insufficientData else { return "" }

        let declarationsList = resolvedCommitments.map { commitment -> String in
            let verdict = commitment.commitmentStatus == .fulfilled ? "FULFILLED" : "BROKEN"
            let reasoning = commitment.verdictReasoning ?? ""
            return "- \"\(commitment.declarationText)\" — \(verdict): \(reasoning)"
        }.joined(separator: "\n")

        return "User's credibility on declared commitments: \(band.promptDescription).\nResolved declarations:\n\(declarationsList)"
    }
}
