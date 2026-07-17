import Foundation
import SwiftData

@Model
final class Conversation {
    var id: UUID
    var startedAt: Date
    var title: String
    var summary: String = ""
    var summarizedMessageCount: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.conversation)
    var messages: [ChatMessage] = []
    
    @Relationship(deleteRule: .nullify, inverse: \JournalEntry.sourceConversation)
    var journalEntry: JournalEntry?

    init(title: String = "New conversation") {
        self.id = UUID()
        self.startedAt = Date()
        self.title = title
    }
}

@Model
final class ChatMessage {
    var id: UUID
    var role: String
    var content: String
    var timestamp: Date

    var conversation: Conversation?

    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role.rawValue
        self.content = content
        self.timestamp = Date()
    }

    var messageRole: MessageRole {
        MessageRole(rawValue: role) ?? .user
    }
}

enum MessageRole: String {
    case user
    case guide
}
