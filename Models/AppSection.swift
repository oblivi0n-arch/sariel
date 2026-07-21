import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case chat
    case journal
    case tribunal
    case vent
    case map
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .chat:
            return "text.bubble.fill"
        case .journal:
            return "bookmark.fill"
        case .tribunal:
            return "seal"
        case .vent:
            return "flame"
        case .map:
            return "moon.stars.fill"
        }
    }
}
