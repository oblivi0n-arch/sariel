import Foundation
import SwiftData

@Model
final class JournalEntryTag {
    var id: UUID
    var name: String
    var entries: [JournalEntry]
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.entries = []
    }
    
    static func deleteIfOrphaned(_ tag: JournalEntryTag, modelContext: ModelContext) {
        guard tag.entries.isEmpty else { return }
        modelContext.delete(tag)
    }
}
