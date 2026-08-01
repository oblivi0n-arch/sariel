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

struct ExportedSelfLetter: Codable {
    let id: UUID
    let title: String?
    let content: String
    let createdAt: Date
    let openDate: Date
    let status: String
    let openedAt: Date?
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
    let selfLetters: [ExportedSelfLetter]
    let aboutMe: String
    let hasCompletedAcquaintance: Bool
    let hasStartedAcquaintance: Bool
    let username: String
    let appTheme: String
    let appThemeFollowsSystem: Bool
    let appLanguage: String
    let journalStyle: String
    let useJournalContext: Bool
    let useCredibilityContext: Bool
    let dashboardShortcut: String
    let chatShortcut: String
    let journalShortcut: String
    let tribunalShortcut: String
    let hasBeenPoorCredibility: Bool
    let lastActiveConversationID: String
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
        selfLetters: [ExportedSelfLetter] = [],
        aboutMe: String,
        hasCompletedAcquaintance: Bool,
        hasStartedAcquaintance: Bool,
        username: String,
        appTheme: String,
        appThemeFollowsSystem: Bool,
        appLanguage: String,
        journalStyle: String,
        useJournalContext: Bool,
        useCredibilityContext: Bool,
        dashboardShortcut: String,
        chatShortcut: String,
        journalShortcut: String,
        tribunalShortcut: String,
        hasBeenPoorCredibility: Bool,
        lastActiveConversationID: String
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
        self.selfLetters = selfLetters
        self.aboutMe = aboutMe
        self.hasCompletedAcquaintance = hasCompletedAcquaintance
        self.hasStartedAcquaintance = hasStartedAcquaintance
        self.username = username
        self.appTheme = appTheme
        self.appThemeFollowsSystem = appThemeFollowsSystem
        self.appLanguage = appLanguage
        self.journalStyle = journalStyle
        self.useJournalContext = useJournalContext
        self.useCredibilityContext = useCredibilityContext
        self.dashboardShortcut = dashboardShortcut
        self.chatShortcut = chatShortcut
        self.journalShortcut = journalShortcut
        self.tribunalShortcut = tribunalShortcut
        self.hasBeenPoorCredibility = hasBeenPoorCredibility
        self.lastActiveConversationID = lastActiveConversationID
    }
    
    enum CodingKeys: String, CodingKey {
        case schemaVersion, appVersion, exportedAt
        case conversations, chatMessages, journalEntries, journalEntryTags, commitments, achievementUnlocks, selfLetters
        case aboutMe, hasCompletedAcquaintance, hasStartedAcquaintance, username
        case appTheme, appThemeFollowsSystem, appLanguage, journalStyle
        case useJournalContext, useCredibilityContext
        case dashboardShortcut, chatShortcut, journalShortcut, tribunalShortcut
        case hasBeenPoorCredibility, lastActiveConversationID
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
        selfLetters = try container.decodeIfPresent([ExportedSelfLetter].self, forKey: .selfLetters) ?? []
        aboutMe = try container.decodeIfPresent(String.self, forKey: .aboutMe) ?? ""
        hasCompletedAcquaintance = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedAcquaintance) ?? false
        hasStartedAcquaintance = try container.decodeIfPresent(Bool.self, forKey: .hasStartedAcquaintance) ?? false
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        appTheme = try container.decodeIfPresent(String.self, forKey: .appTheme) ?? AppTheme.dark.rawValue
        appThemeFollowsSystem = try container.decodeIfPresent(Bool.self, forKey: .appThemeFollowsSystem) ?? false
        appLanguage = try container.decodeIfPresent(String.self, forKey: .appLanguage) ?? ""
        journalStyle = try container.decodeIfPresent(String.self, forKey: .journalStyle) ?? JournalStyle.conciseFactual.rawValue
        useJournalContext = try container.decodeIfPresent(Bool.self, forKey: .useJournalContext) ?? false
        useCredibilityContext = try container.decodeIfPresent(Bool.self, forKey: .useCredibilityContext) ?? false
        dashboardShortcut = try container.decodeIfPresent(String.self, forKey: .dashboardShortcut) ?? ShortcutAction.dashboard.defaultShortcut.rawValue
        chatShortcut = try container.decodeIfPresent(String.self, forKey: .chatShortcut) ?? ShortcutAction.chat.defaultShortcut.rawValue
        journalShortcut = try container.decodeIfPresent(String.self, forKey: .journalShortcut) ?? ShortcutAction.journal.defaultShortcut.rawValue
        tribunalShortcut = try container.decodeIfPresent(String.self, forKey: .tribunalShortcut) ?? ShortcutAction.tribunal.defaultShortcut.rawValue
        hasBeenPoorCredibility = try container.decodeIfPresent(Bool.self, forKey: .hasBeenPoorCredibility) ?? false
        lastActiveConversationID = try container.decodeIfPresent(String.self, forKey: .lastActiveConversationID) ?? ""
    }
}
