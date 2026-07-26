import Foundation
import SwiftData
import Combine

@MainActor
final class AchievementService: ObservableObject {
    @Published var newlyUnlocked: AchievementKind?

    func allUnlocks(modelContext: ModelContext) -> [AchievementUnlock] {
        var existing = (try? modelContext.fetch(FetchDescriptor<AchievementUnlock>())) ?? []
        let existingKinds = Set(existing.compactMap { $0.achievementKind })

        for kind in AchievementKind.allCases where !existingKinds.contains(kind) {
            let unlock = AchievementUnlock(kind: kind)
            modelContext.insert(unlock)
            existing.append(unlock)
        }

        return existing
    }
    
    func checkNightOwl(modelContext: ModelContext) {
        let allEntries = (try? modelContext.fetch(FetchDescriptor<JournalEntry>())) ?? []

        let nightEntries = allEntries.filter { entry in
            let hour = Calendar.current.component(.hour, from: entry.createdAt)
            return hour >= 0 && hour < 4
        }

        updateProgress(for: .nightOwl, count: nightEntries.count, modelContext: modelContext)
    }
    
    func checkConsistencyStreak(modelContext: ModelContext) {
        let allEntries = (try? modelContext.fetch(FetchDescriptor<JournalEntry>())) ?? []
        let dayKeys = Set(allEntries.map { $0.createdAt.dayKey })

        var streak = 0
        var cursor = Date()
        while dayKeys.contains(cursor.dayKey) {
            streak += 1
            cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }

        updateProgress(for: .consistencyStreak, count: streak, modelContext: modelContext)
    }
    
    func checkReturnedAfterSilence(modelContext: ModelContext) {
        let allEntries = (try? modelContext.fetch(
            FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        )) ?? []
        guard allEntries.count >= 2 else { return }

        let silenceThreshold: TimeInterval = 21 * 24 * 60 * 60
        let gap = allEntries[0].createdAt.timeIntervalSince(allEntries[1].createdAt)

        unlockIfNeeded(.returnedAfterSilence, condition: gap >= silenceThreshold, modelContext: modelContext)
    }
    
    func checkWritingSpiral(modelContext: ModelContext) {
        let allEntries = (try? modelContext.fetch(
            FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        )) ?? []
        guard allEntries.count >= 3 else { return }

        let oneHour: TimeInterval = 60 * 60
        let spanOfLastThree = allEntries[0].createdAt.timeIntervalSince(allEntries[2].createdAt)

        unlockIfNeeded(.writingSpiral, condition: spanOfLastThree <= oneHour, modelContext: modelContext)
    }
    
    func checkRecurringTag(modelContext: ModelContext) {
        let allEntries = (try? modelContext.fetch(FetchDescriptor<JournalEntry>())) ?? []

        var tagCounts: [UUID: Int] = [:]
        for entry in allEntries {
            for tag in entry.tags {
                tagCounts[tag.id, default: 0] += 1
            }
        }

        let maxCount = tagCounts.values.max() ?? 0
        updateProgress(for: .recurringTag, count: maxCount, modelContext: modelContext)
    }

    private func updateProgress(for kind: AchievementKind, count: Int, modelContext: ModelContext) {
        let unlocks = allUnlocks(modelContext: modelContext)
        guard let unlock = unlocks.first(where: { $0.achievementKind == kind }) else { return }
        guard unlock.unlockedAt == nil else { return }

        unlock.progress = count

        if let target = kind.targetCount, count >= target {
            unlock.unlockedAt = Date()
            newlyUnlocked = kind
        }

        try? modelContext.save()
    }
    
    private func unlockIfNeeded(_ kind: AchievementKind, condition: Bool, modelContext: ModelContext) {
        guard condition else { return }

        let unlocks = allUnlocks(modelContext: modelContext)
        guard let unlock = unlocks.first(where: { $0.achievementKind == kind }) else { return }
        guard unlock.unlockedAt == nil else { return }

        unlock.progress = 1
        unlock.unlockedAt = Date()
        newlyUnlocked = kind

        try? modelContext.save()
    }
}
