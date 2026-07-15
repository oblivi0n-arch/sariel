import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case chat
    case journal
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .chat:
            return "bubble.left.and.bubble.right.fill"
        case .journal:
            return "book.closed.fill"
        }
    }
}
