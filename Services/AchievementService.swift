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
}
