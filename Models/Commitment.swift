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
}

enum CommitmentStatus: String {
    case pending
    case fulfilled
    case broken
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
}
