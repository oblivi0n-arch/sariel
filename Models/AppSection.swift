import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case chat
    case journal
    case tribunal
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .dashboard:
            return "moon.stars.fill"
        case .chat:
            return "text.bubble.fill"
        case .journal:
            return "bookmark.fill"
        case .tribunal:
            return "seal"
        }
    }
}
