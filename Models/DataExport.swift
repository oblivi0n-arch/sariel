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
