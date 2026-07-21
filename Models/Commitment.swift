import Foundation
import SwiftData

@Model
final class Commitment {
    var id: UUID
    var declarationText: String
    var createdAt: Date
    var status: String = CommitmentStatus.pending.rawValue

    var resolvedAt: Date?
    var verdictReasoning: String?
    var stepsDescription: String?

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.commitment)
    var sourceMessage: ChatMessage?

    @Relationship(deleteRule: .nullify)
    var resolvingConversation: Conversation?

    init(declarationText: String, sourceMessage: ChatMessage? = nil) {
        self.id = UUID()
        self.declarationText = declarationText
        self.createdAt = Date()
        self.sourceMessage = sourceMessage
    }

    var commitmentStatus: CommitmentStatus {
        get { CommitmentStatus(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }
    
    static let tribunalUnlockInterval: TimeInterval = 7 * 24 * 60 * 60

    static func isDeclaration(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .hasPrefix("i declare")
    }
    
    static let credibilitySampleMinimum = 3

    static func credibilityBand(from commitments: [Commitment]) -> CredibilityBand {
        let resolved = commitments.filter { $0.commitmentStatus != .pending }
        guard resolved.count >= credibilitySampleMinimum else { return .insufficientData }

        let fulfilledCount = resolved.filter { $0.commitmentStatus == .fulfilled }.count
        let percentage = Double(fulfilledCount) / Double(resolved.count) * 100

        switch percentage {
        case 0..<40: return .poor
        case 40..<70: return .mixed
        default: return .solid
        }
    }
    
    static func credibilityPercentage(from commitments: [Commitment]) -> Double? {
        let resolved = commitments.filter { $0.commitmentStatus != .pending }
        guard resolved.count >= credibilitySampleMinimum else { return nil }

        let fulfilledCount = resolved.filter { $0.commitmentStatus == .fulfilled }.count
        return Double(fulfilledCount) / Double(resolved.count) * 100
    }
}

enum CommitmentStatus: String {
    case pending
    case fulfilled
    case broken
}

enum CredibilityBand: String {
    case insufficientData
    case poor
    case mixed
    case solid

    var promptDescription: String {
        switch self {
        case .insufficientData: return "not enough resolved declarations yet to judge"
        case .poor:   return "poor — mostly breaks declared commitments"
        case .mixed:  return "mixed — sometimes keeps declared commitments, sometimes breaks them"
        case .solid:  return "solid — mostly keeps declared commitments"
        }
    }
}
