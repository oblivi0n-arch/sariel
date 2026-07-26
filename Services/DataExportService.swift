import Foundation
import SwiftData

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
}
