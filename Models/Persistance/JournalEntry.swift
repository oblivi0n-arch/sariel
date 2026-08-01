import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var isPinned: Bool = false
    var isArchived: Bool = false    
    var mood: String
    var sourceConversation: Conversation?
    @Relationship(inverse: \JournalEntryTag.entries) var tags: [JournalEntryTag] = []

    init(title: String = L10n.Journal.newEntryTitle, content: String = "", mood: Mood = .neutral) {
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

extension Mood {
    var displayName: String {
        switch self {
        case .great: return L10n.Mood.great
        case .good: return L10n.Mood.good
        case .neutral: return L10n.Mood.neutral
        case .bad: return L10n.Mood.bad
        case .awful: return L10n.Mood.awful
        }
    }
}

extension L10n {
    enum Mood {
        static var great: String {
            switch lang {
            case .en: return "great"
            case .pl: return "świetnie"
            }
        }
        static var good: String {
            switch lang {
            case .en: return "good"
            case .pl: return "dobrze"
            }
        }
        static var neutral: String {
            switch lang {
            case .en: return "neutral"
            case .pl: return "neutralnie"
            }
        }
        static var bad: String {
            switch lang {
            case .en: return "bad"
            case .pl: return "źle"
            }
        }
        static var awful: String {
            switch lang {
            case .en: return "awful"
            case .pl: return "okropnie"
            }
        }
    }
}
