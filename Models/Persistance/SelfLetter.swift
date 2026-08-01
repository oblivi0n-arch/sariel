import Foundation
import SwiftData

enum SelfLetterStatus: String {
    case draft
    case sealed
    case available
    case opened
}

enum SelfLetterDelay: String, CaseIterable {
    case oneMonth
    case twoMonths
    case threeMonths
    case sixMonths
    case oneYear

    func openDate(from now: Date = Date()) -> Date {
        let calendar = Calendar.current
        switch self {
        case .oneMonth:    return calendar.date(byAdding: .month, value: 1, to: now)!
        case .twoMonths:   return calendar.date(byAdding: .month, value: 2, to: now)!
        case .threeMonths: return calendar.date(byAdding: .month, value: 3, to: now)!
        case .sixMonths:   return calendar.date(byAdding: .month, value: 6, to: now)!
        case .oneYear:     return calendar.date(byAdding: .year, value: 1, to: now)!
        }
    }

    var displayName: String {
        switch self {
        case .oneMonth:    return L10n.lang == .pl ? "za miesiąc" : "in a month"
        case .twoMonths:   return L10n.lang == .pl ? "za 2 miesiące" : "in 2 months"
        case .threeMonths: return L10n.lang == .pl ? "za 3 miesiące" : "in 3 months"
        case .sixMonths:   return L10n.lang == .pl ? "za pół roku" : "in 6 months"
        case .oneYear:     return L10n.lang == .pl ? "za rok" : "in a year"
        }
    }
}

@Model
final class SelfLetter {
    var id: UUID
    var title: String?
    var content: String
    var createdAt: Date
    var openDate: Date
    var status: String = SelfLetterStatus.draft.rawValue
    var openedAt: Date?
    
    init(title: String? = nil, content: String, openDate: Date) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.openDate = openDate
    }
    
    var letterStatus: SelfLetterStatus {
        get { SelfLetterStatus(rawValue: status) ?? .sealed }
        set { status = newValue.rawValue }
    }
    
    static let maxActiveLetters = 5
}
