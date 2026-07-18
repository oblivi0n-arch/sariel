import Foundation

struct Toast: Identifiable {
    let id = UUID()
    let entry: JournalEntry
    let duration: TimeInterval = 7.0
}
