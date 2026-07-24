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

        return "\(L10n.PromptCredibility.summaryIntro(band.promptDescription))\n\(L10n.PromptCredibility.resolvedDeclarationsLabel)\n\(declarationsList)"
    }
}

extension L10n {
    enum PromptCredibility {
        static func summaryIntro(_ description: String) -> String {
            switch lang {
            case .en: return "User's credibility on declared commitments: \(description)."
            case .pl: return "Wiarygodność użytkownika w sprawie zadeklarowanych zobowiązań: \(description)."
            }
        }

        static var resolvedDeclarationsLabel: String {
            switch lang {
            case .en: return "Resolved declarations:"
            case .pl: return "Rozstrzygnięte deklaracje:"
            }
        }
    }
}
