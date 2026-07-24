import Foundation
import SwiftData

@Model
final class Commitment {
    var id: UUID
    var declarationText: String
    var createdAt: Date
    var status: String = CommitmentStatus.pending.rawValue
    var failureMeaning: String = ""

    var resolvedAt: Date?
    var verdictReasoning: String?
    var stepsDescription: String?

    @Relationship(deleteRule: .nullify, inverse: \ChatMessage.commitment)
    var sourceMessage: ChatMessage?

    @Relationship(deleteRule: .nullify)
    var resolvingConversation: Conversation?

    init(declarationText: String, failureMeaning: String, sourceMessage: ChatMessage? = nil) {
        self.id = UUID()
        self.declarationText = declarationText
        self.createdAt = Date()
        self.failureMeaning = failureMeaning
        self.sourceMessage = sourceMessage
    }

    var commitmentStatus: CommitmentStatus {
        get { CommitmentStatus(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }
    
    static let tribunalUnlockInterval: TimeInterval = 3 * 24 * 60 * 60
    static let maxPendingDeclarations = 3

    static func isDeclaration(_ text: String) -> Bool {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return L10n.Declaration.allPrefixVariants.contains { normalized.hasPrefix($0) }
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

    var displayName: String {
        switch self {
        case .insufficientData: return L10n.Credibility.insufficientData
        case .poor: return L10n.Credibility.poor
        case .mixed: return L10n.Credibility.mixed
        case .solid: return L10n.Credibility.solid
        }
    }
}

extension L10n {
    enum Declaration {
        static func prefix(for language: AppLanguage) -> String {
            switch language {
            case .en: return "i declare"
            case .pl: return "ja deklaruję"
            }
        }

        static var allPrefixVariants: [String] {
            AppLanguage.allCases.map { prefix(for: $0) }
        }
    }

    enum Credibility {
        static var insufficientData: String {
            switch lang {
            case .en: return "insufficient data"
            case .pl: return "za mało danych"
            }
        }
        static var poor: String {
            switch lang {
            case .en: return "poor"
            case .pl: return "słaba"
            }
        }
        static var mixed: String {
            switch lang {
            case .en: return "mixed"
            case .pl: return "mieszana"
            }
        }
        static var solid: String {
            switch lang {
            case .en: return "solid"
            case .pl: return "solidna"
            }
        }
    }
}
