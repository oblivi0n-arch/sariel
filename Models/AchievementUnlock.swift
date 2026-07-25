import Foundation
import SwiftData

@Model
final class AchievementUnlock {
    var id: UUID
    var kind: String
    var progress: Int = 0
    var unlockedAt: Date?

    init(kind: AchievementKind) {
        self.id = UUID()
        self.kind = kind.rawValue
        self.progress = 0
        self.unlockedAt = nil
    }

    var achievementKind: AchievementKind? {
        AchievementKind(rawValue: kind)
    }

    var isUnlocked: Bool {
        unlockedAt != nil
    }
}
