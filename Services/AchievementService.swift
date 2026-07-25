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
}
