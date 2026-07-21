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
}

enum CommitmentStatus: String {
    case pending
    case fulfilled
    case broken
}
