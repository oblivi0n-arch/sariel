import Foundation
import SwiftData

@Model
final class MeditationSession {
    var id: UUID
    var intention: String
    var plannedDuration: TimeInterval
    var actualDuration: TimeInterval
    var createdAt: Date

    init(intention: String, plannedDuration: TimeInterval, actualDuration: TimeInterval) {
        self.id = UUID()
        self.intention = intention
        self.plannedDuration = plannedDuration
        self.actualDuration = actualDuration
        self.createdAt = Date()
    }

    var wasInterrupted: Bool {
        actualDuration < plannedDuration
    }
}

enum MeditationDuration: Int, CaseIterable {
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case twentyMinutes = 20
    case thirtyMinutes = 30

    var seconds: TimeInterval {
        TimeInterval(rawValue * 60)
    }

    var displayName: String {
        switch L10n.lang {
        case .en: return "\(rawValue) min"
        case .pl: return "\(rawValue) min"
        }
    }
}
