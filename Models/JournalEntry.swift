import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var isPinned: Bool = false
    var mood: String
    var sourceConversation: Conversation?
    @Relationship(inverse: \JournalEntryTag.entries) var tags: [JournalEntryTag] = []

    init(title: String = "New entry", content: String = "", mood: Mood = .neutral) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.mood = mood.rawValue
    }

    var entryMood: Mood {
        get { Mood(rawValue: mood) ?? .neutral }
        set { mood = newValue.rawValue }
    }
}

enum Mood: String, CaseIterable {
    case great, good, neutral, bad, awful

    var symbolName: String {
        switch self {
        case .great:   "sun.max"
        case .good:    "cloud.sun"
        case .neutral: "cloud"
        case .bad:     "cloud.rain"
        case .awful:   "cloud.bolt.rain"
        }
    }
    
    var accentOpacity: Double {
        switch self {
        case .great:   1.0
        case .good:    0.75
        case .neutral: 0.5
        case .bad:     0.3
        case .awful:   0.15
        }
    }
}
