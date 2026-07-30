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
    let isAcquaintance: Bool
    let acquaintanceQuestion: String?
    let isTribunal: Bool
    let tribunalResolvedAt: Date?
    let isArchived: Bool

    init(
        id: UUID,
        startedAt: Date,
        title: String,
        summary: String,
        summarizedMessageCount: Int,
        isProvocation: Bool,
        provocationQuestion: String?,
        provocationTitle: String?,
        isAcquaintance: Bool,
        acquaintanceQuestion: String?,
        isTribunal: Bool,
        tribunalResolvedAt: Date?,
        isArchived: Bool
    ) {
        self.id = id
        self.startedAt = startedAt
        self.title = title
        self.summary = summary
        self.summarizedMessageCount = summarizedMessageCount
        self.isProvocation = isProvocation
        self.provocationQuestion = provocationQuestion
        self.provocationTitle = provocationTitle
        self.isAcquaintance = isAcquaintance
        self.acquaintanceQuestion = acquaintanceQuestion
        self.isTribunal = isTribunal
        self.tribunalResolvedAt = tribunalResolvedAt
        self.isArchived = isArchived
    }

    enum CodingKeys: String, CodingKey {
        case id, startedAt, title, summary, summarizedMessageCount
        case isProvocation, provocationQuestion, provocationTitle
        case isAcquaintance, acquaintanceQuestion
        case isTribunal, tribunalResolvedAt, isArchived
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decode(String.self, forKey: .summary)
        summarizedMessageCount = try container.decode(Int.self, forKey: .summarizedMessageCount)
        isProvocation = try container.decode(Bool.self, forKey: .isProvocation)
        provocationQuestion = try container.decodeIfPresent(String.self, forKey: .provocationQuestion)
        provocationTitle = try container.decodeIfPresent(String.self, forKey: .provocationTitle)
        isAcquaintance = try container.decodeIfPresent(Bool.self, forKey: .isAcquaintance) ?? false
        acquaintanceQuestion = try container.decodeIfPresent(String.self, forKey: .acquaintanceQuestion)
        isTribunal = try container.decode(Bool.self, forKey: .isTribunal)
        tribunalResolvedAt = try container.decodeIfPresent(Date.self, forKey: .tribunalResolvedAt)
        isArchived = try container.decode(Bool.self, forKey: .isArchived)
    }
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
    let aboutMe: String
    let hasCompletedAcquaintance: Bool
    let hasStartedAcquaintance: Bool
    let username: String
}

extension SarielExport {
    static let currentSchemaVersion = 1

    init(
        conversations: [ExportedConversation],
        chatMessages: [ExportedChatMessage],
        journalEntries: [ExportedJournalEntry],
        journalEntryTags: [ExportedJournalEntryTag],
        commitments: [ExportedCommitment],
        achievementUnlocks: [ExportedAchievementUnlock],
        aboutMe: String,
        hasCompletedAcquaintance: Bool,
        hasStartedAcquaintance: Bool,
        username: String
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
        self.aboutMe = aboutMe
        self.hasCompletedAcquaintance = hasCompletedAcquaintance
        self.hasStartedAcquaintance = hasStartedAcquaintance
        self.username = username
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion, appVersion, exportedAt
        case conversations, chatMessages, journalEntries, journalEntryTags, commitments, achievementUnlocks
        case aboutMe, hasCompletedAcquaintance, hasStartedAcquaintance, username
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        appVersion = try container.decode(String.self, forKey: .appVersion)
        exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        conversations = try container.decode([ExportedConversation].self, forKey: .conversations)
        chatMessages = try container.decode([ExportedChatMessage].self, forKey: .chatMessages)
        journalEntries = try container.decode([ExportedJournalEntry].self, forKey: .journalEntries)
        journalEntryTags = try container.decode([ExportedJournalEntryTag].self, forKey: .journalEntryTags)
        commitments = try container.decode([ExportedCommitment].self, forKey: .commitments)
        achievementUnlocks = try container.decode([ExportedAchievementUnlock].self, forKey: .achievementUnlocks)
        aboutMe = try container.decodeIfPresent(String.self, forKey: .aboutMe) ?? ""
        hasCompletedAcquaintance = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedAcquaintance) ?? false
        hasStartedAcquaintance = try container.decodeIfPresent(Bool.self, forKey: .hasStartedAcquaintance) ?? false
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
    }
}
