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
            return "bubble.left.and.bubble.right.fill"
        case .journal:
            return "book.closed.fill"
        case .tribunal:
            return "seal"
        }
    }
}
