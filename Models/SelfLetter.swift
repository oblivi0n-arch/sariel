import Foundation
import SwiftData

enum SelfLetterStatus: String {
    case sealed
    case available
    case opened
}

enum SelfLetterDelay: String, CaseIterable {
    case oneWeek
    case oneMonth
    case threeMonths
    case oneYear
    
    func openDate(from now: Date = Date()) -> Date {
        let calendar = Calendar.current
        switch self {
        case .oneWeek:     return calendar.date(byAdding: .day, value: 7, to: now)!
        case .oneMonth:    return calendar.date(byAdding: .month, value: 1, to: now)!
        case .threeMonths: return calendar.date(byAdding: .month, value: 3, to: now)!
        case .oneYear:     return calendar.date(byAdding: .year, value: 1, to: now)!
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
    var status: String = SelfLetterStatus.sealed.rawValue
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
