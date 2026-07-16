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
}
