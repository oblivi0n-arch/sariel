import Foundation

enum ToastKind {
    case journalEntrySaved(JournalEntry)
    case declarationLimitBlocked
    case declarationRequiresNewMessage
    case achievementUnlocked(AchievementKind)
    case selfLetterAvailable(SelfLetter)
}

struct Toast: Identifiable {
    let id = UUID()
    let kind: ToastKind
    let duration: TimeInterval = 7.0
}
