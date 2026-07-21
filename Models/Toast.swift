import Foundation

enum ToastKind {
    case journalEntrySaved(JournalEntry)
    case tribunalUnlocked
    case declarationLimitBlocked
}

struct Toast: Identifiable {
    let id = UUID()
    let kind: ToastKind
    let duration: TimeInterval = 7.0
}
