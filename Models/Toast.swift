import Foundation

enum ToastKind {
    case journalEntrySaved(JournalEntry)
    case tribunalUnlocked
    case declarationLimitBlocked
    case declarationRequiresNewMessage
    case achievementUnlocked(AchievementKind)
}

struct Toast: Identifiable {
    let id = UUID()
    let kind: ToastKind
    let duration: TimeInterval = 7.0
}
