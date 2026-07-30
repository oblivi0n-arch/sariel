import Foundation

enum JournalStyle: String, CaseIterable {
    case conciseFactual
    case extendedFactual
    case extendedNarrative

    var displayName: String {
        switch self {
        case .conciseFactual: return L10n.JournalStyle.conciseFactualTitle
        case .extendedFactual: return L10n.JournalStyle.extendedFactualTitle
        case .extendedNarrative: return L10n.JournalStyle.extendedNarrativeTitle
        }
    }

    var subtitle: String {
        switch self {
        case .conciseFactual: return L10n.JournalStyle.conciseFactualSubtitle
        case .extendedFactual: return L10n.JournalStyle.extendedFactualSubtitle
        case .extendedNarrative: return L10n.JournalStyle.extendedNarrativeSubtitle
        }
    }
}

extension L10n {
    enum JournalStyle {
        static var sectionTitle: String {
            switch lang {
            case .en: return "JOURNAL ENTRY STYLE"
            case .pl: return "STYL WPISÓW W DZIENNIKU"
            }
        }

        static var sectionHint: String {
            switch lang {
            case .en: return "Controls how Sariel writes the journal entry generated when you end a conversation."
            case .pl: return "Wpływa na to, jak Sariel pisze wpis do dziennika generowany po zakończeniu rozmowy."
            }
        }

        static var conciseFactualTitle: String {
            switch lang {
            case .en: return "Concise record"
            case .pl: return "Zwięzły zapis faktu"
            }
        }

        static var conciseFactualSubtitle: String {
            switch lang {
            case .en: return "2-3 sentences, no embellishment."
            case .pl: return "2-3 zdania, bez ozdobników."
            }
        }

        static var extendedFactualTitle: String {
            switch lang {
            case .en: return "Extended analysis"
            case .pl: return "Rozbudowana analiza"
            }
        }

        static var extendedFactualSubtitle: String {
            switch lang {
            case .en: return "Longer, still direct — no scene-setting."
            case .pl: return "Dłuższy, ale wciąż rzeczowy — bez scenerii."
            }
        }

        static var extendedNarrativeTitle: String {
            switch lang {
            case .en: return "Extended story"
            case .pl: return "Rozbudowana opowieść"
            }
        }

        static var extendedNarrativeSubtitle: String {
            switch lang {
            case .en: return "Longer, with a scene and a sense of moment."
            case .pl: return "Dłuższy, ze sceną i poczuciem chwili."
            }
        }
    }
}
