import Foundation

struct ExportedAchievementUnlock: Codable {
    let id: UUID
    let kind: String
    let progress: Int
    let unlockedAt: Date?
}

struct ExportedJournalEntryTag: Codable {
    let id: UUID
    let name: String
}

struct ExportedJournalEntry: Codable {
    let id: UUID
    let title: String
    let content: String
    let createdAt: Date
    let isPinned: Bool
    let mood: String
    let sourceConversationID: UUID?
    let tagIDs: [UUID]
}

struct ExportedCommitment: Codable {
    let id: UUID
    let declarationText: String
    let createdAt: Date
    let status: String
    let failureMeaning: String
    let resolvedAt: Date?
    let verdictReasoning: String?
    let stepsDescription: String?
    let sourceMessageID: UUID?
    let resolvingConversationID: UUID?
}

struct ExportedChatMessage: Codable {
    let id: UUID
    let role: String
    let content: String
    let timestamp: Date
    let conversationID: UUID?
    let commitmentID: UUID?
}

struct ExportedConversation: Codable {
    let id: UUID
    let startedAt: Date
    let title: String
    let summary: String
    let summarizedMessageCount: Int
    let isProvocation: Bool
    let provocationQuestion: String?
    let provocationTitle: String?
    let isTribunal: Bool
    let tribunalResolvedAt: Date?
    let isArchived: Bool
}

struct SarielExport: Codable {
    let schemaVersion: Int
    let appVersion: String
    let exportedAt: Date

    let conversations: [ExportedConversation]
    let chatMessages: [ExportedChatMessage]
    let journalEntries: [ExportedJournalEntry]
    let journalEntryTags: [ExportedJournalEntryTag]
    let commitments: [ExportedCommitment]
    let achievementUnlocks: [ExportedAchievementUnlock]
}

extension SarielExport {
    static let currentSchemaVersion = 1

    init(
        conversations: [ExportedConversation],
        chatMessages: [ExportedChatMessage],
        journalEntries: [ExportedJournalEntry],
        journalEntryTags: [ExportedJournalEntryTag],
        commitments: [ExportedCommitment],
        achievementUnlocks: [ExportedAchievementUnlock]
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        self.exportedAt = Date()
        self.conversations = conversations
        self.chatMessages = chatMessages
        self.journalEntries = journalEntries
        self.journalEntryTags = journalEntryTags
        self.commitments = commitments
        self.achievementUnlocks = achievementUnlocks
    }
}
