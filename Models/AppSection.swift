import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case chat
    case journal
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .chat:
            return "text.bubble.fill"
        case .journal:
            return "bookmark.fill"
        }
    }
}
