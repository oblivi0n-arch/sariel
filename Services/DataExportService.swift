import Foundation
import SwiftData
import AppKit
import UniformTypeIdentifiers

enum DataExportService {
    static func exportAllData(modelContext: ModelContext) throws -> SarielExport {
        let achievementUnlocks = try modelContext.fetch(FetchDescriptor<AchievementUnlock>())
            .map { unlock in
                ExportedAchievementUnlock(
                    id: unlock.id,
                    kind: unlock.kind,
                    progress: unlock.progress,
                    unlockedAt: unlock.unlockedAt
                )
            }
        let journalEntryTags = try modelContext.fetch(FetchDescriptor<JournalEntryTag>())
            .map { tag in
                    ExportedJournalEntryTag(
                    id: tag.id,
                    name: tag.name
                )
            }
        let chatMessages = try modelContext.fetch(FetchDescriptor<ChatMessage>())
            .map { chatMessage in
                    ExportedChatMessage(
                        id: chatMessage.id,
                        role: chatMessage.role,
                        content: chatMessage.content,
                        timestamp: chatMessage.timestamp,
                        conversationID: chatMessage.conversation?.id,
                        commitmentID: chatMessage.commitment?.id
                        )
            }
        let journalEntries = try modelContext.fetch(FetchDescriptor<JournalEntry>())
            .map { entry in
                ExportedJournalEntry(
                    id: entry.id,
                    title: entry.title,
                    content: entry.content,
                    createdAt: entry.createdAt,
                    isPinned: entry.isPinned,
                    mood: entry.mood,
                    sourceConversationID: entry.sourceConversation?.id,
                    tagIDs: entry.tags.map { tag in tag.id }
                )
            }
        let conversations = try modelContext.fetch(FetchDescriptor<Conversation>())
            .map { conversation in
                ExportedConversation(
                    id: conversation.id,
                    startedAt: conversation.startedAt,
                    title: conversation.title,
                    summary: conversation.summary,
                    summarizedMessageCount: conversation.summarizedMessageCount,
                    isProvocation: conversation.isProvocation,
                    provocationQuestion: conversation.provocationQuestion,
                    provocationTitle: conversation.provocationTitle,
                    isTribunal: conversation.isTribunal,
                    tribunalResolvedAt: conversation.tribunalResolvedAt,
                    isArchived: conversation.isArchived
                )
            }
        let commitments = try modelContext.fetch(FetchDescriptor<Commitment>())
            .map { commitment in
                ExportedCommitment(
                    id: commitment.id,
                    declarationText: commitment.declarationText,
                    createdAt: commitment.createdAt,
                    status: commitment.status,
                    failureMeaning: commitment.failureMeaning,
                    resolvedAt: commitment.resolvedAt,
                    verdictReasoning: commitment.verdictReasoning,
                    stepsDescription: commitment.stepsDescription,
                    sourceMessageID: commitment.sourceMessage?.id,
                    resolvingConversationID: commitment.resolvingConversation?.id
                )
            }
        
        return SarielExport(
            conversations: conversations,
            chatMessages: chatMessages,
            journalEntries: journalEntries,
            journalEntryTags: journalEntryTags,
            commitments: commitments,
            achievementUnlocks: achievementUnlocks
        )
    }
    
    static func encodeToJSON(_ export: SarielExport) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(export)
    }
    
    static func decodeFromJSON(_ data: Data) throws -> SarielExport {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SarielExport.self, from: data)
    }
}

extension DataExportService {
    @MainActor
    static func presentSavePanel(suggestedName: String = "sariel-export.json") -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = suggestedName
        panel.title = "Eksportuj dane Sariel"

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}

extension DataExportService {
    static func deleteAll<T: PersistentModel>(_ type: T.Type, modelContext: ModelContext) {
        guard let objects = try? modelContext.fetch(FetchDescriptor<T>()) else { return }
        for object in objects {
            modelContext.delete(object)
        }
    }
}

extension DataExportService {
    @MainActor
    static func importAllData(_ export: SarielExport, modelContext: ModelContext) throws {
        try export.validateSchemaVersion()
        
        deleteAll(Conversation.self, modelContext: modelContext)
        deleteAll(ChatMessage.self, modelContext: modelContext)
        deleteAll(JournalEntry.self, modelContext: modelContext)
        deleteAll(JournalEntryTag.self, modelContext: modelContext)
        deleteAll(Commitment.self, modelContext: modelContext)
        deleteAll(AchievementUnlock.self, modelContext: modelContext)

        var conversationsByID: [UUID: Conversation] = [:]
        for exported in export.conversations {
            let conversation = Conversation(title: exported.title)
            conversation.id = exported.id
            conversation.startedAt = exported.startedAt
            conversation.summary = exported.summary
            conversation.summarizedMessageCount = exported.summarizedMessageCount
            conversation.isProvocation = exported.isProvocation
            conversation.provocationQuestion = exported.provocationQuestion
            conversation.provocationTitle = exported.provocationTitle
            conversation.isTribunal = exported.isTribunal
            conversation.tribunalResolvedAt = exported.tribunalResolvedAt
            conversation.isArchived = exported.isArchived
            modelContext.insert(conversation)
            conversationsByID[exported.id] = conversation
        }

        var tagsByID: [UUID: JournalEntryTag] = [:]
        for exported in export.journalEntryTags {
            let tag = JournalEntryTag(name: exported.name)
            tag.id = exported.id
            modelContext.insert(tag)
            tagsByID[exported.id] = tag
        }

        var messagesByID: [UUID: ChatMessage] = [:]
        for exported in export.chatMessages {
            let role = MessageRole(rawValue: exported.role) ?? .user
            let message = ChatMessage(role: role, content: exported.content)
            message.id = exported.id
            message.timestamp = exported.timestamp
            modelContext.insert(message)
            messagesByID[exported.id] = message
        }

        var entriesByID: [UUID: JournalEntry] = [:]
        for exported in export.journalEntries {
            let mood = Mood(rawValue: exported.mood) ?? .neutral
            let entry = JournalEntry(title: exported.title, content: exported.content, mood: mood)
            entry.id = exported.id
            entry.createdAt = exported.createdAt
            entry.isPinned = exported.isPinned
            modelContext.insert(entry)
            entriesByID[exported.id] = entry
        }

        var commitmentsByID: [UUID: Commitment] = [:]
        for exported in export.commitments {
            let commitment = Commitment(declarationText: exported.declarationText, failureMeaning: exported.failureMeaning)
            commitment.id = exported.id
            commitment.createdAt = exported.createdAt
            commitment.status = exported.status
            commitment.resolvedAt = exported.resolvedAt
            commitment.verdictReasoning = exported.verdictReasoning
            commitment.stepsDescription = exported.stepsDescription
            modelContext.insert(commitment)
            commitmentsByID[exported.id] = commitment
        }

        for exported in export.achievementUnlocks {
            guard let kind = AchievementKind(rawValue: exported.kind) else { continue }
            let unlock = AchievementUnlock(kind: kind)
            unlock.id = exported.id
            unlock.progress = exported.progress
            unlock.unlockedAt = exported.unlockedAt
            modelContext.insert(unlock)
        }

        for exported in export.chatMessages {
            guard let message = messagesByID[exported.id] else { continue }
            message.conversation = exported.conversationID.flatMap { conversationsByID[$0] }
            message.commitment = exported.commitmentID.flatMap { commitmentsByID[$0] }
        }

        for exported in export.journalEntries {
            guard let entry = entriesByID[exported.id] else { continue }
            entry.sourceConversation = exported.sourceConversationID.flatMap { conversationsByID[$0] }
            entry.tags = exported.tagIDs.compactMap { tagsByID[$0] }
        }

        for exported in export.commitments {
            guard let commitment = commitmentsByID[exported.id] else { continue }
            commitment.sourceMessage = exported.sourceMessageID.flatMap { messagesByID[$0] }
            commitment.resolvingConversation = exported.resolvingConversationID.flatMap { conversationsByID[$0] }
        }

        try modelContext.save()
    }
}

extension L10n {
    enum DataImport {
        static func incompatibleSchemaVersion(fileVersion: Int, supportedVersion: Int) -> String {
            switch L10n.lang {
            case .en: return "This file uses an unsupported format version (\(fileVersion)); this app supports version \(supportedVersion)."
            case .pl: return "Ten plik używa nieobsługiwanej wersji formatu (\(fileVersion)); aplikacja obsługuje wersję \(supportedVersion)."
            }
        }

        static func corruptedFile() -> String {
            switch L10n.lang {
            case .en: return "Couldn't read this file — it may be corrupted or in the wrong format."
            case .pl: return "Nie udało się odczytać pliku — jest uszkodzony lub ma zły format."
            }
        }
    }
}

enum DataImportError: LocalizedError {
    case incompatibleSchemaVersion(fileVersion: Int, supportedVersion: Int)
    case corruptedFile(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .incompatibleSchemaVersion(let fileVersion, let supportedVersion):
            return L10n.DataImport.incompatibleSchemaVersion(fileVersion: fileVersion, supportedVersion: supportedVersion)
        case .corruptedFile:
            return L10n.DataImport.corruptedFile()
        }
    }
}

extension SarielExport {
    func validateSchemaVersion() throws {
        guard schemaVersion == SarielExport.currentSchemaVersion else {
            throw DataImportError.incompatibleSchemaVersion(
                fileVersion: schemaVersion,
                supportedVersion: SarielExport.currentSchemaVersion
            )
        }
    }
}
