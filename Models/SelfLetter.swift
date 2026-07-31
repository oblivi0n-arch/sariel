import Foundation
import SwiftData

enum SelfLetterStatus: String {
    case sealed
    case available
    case opened
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
}
