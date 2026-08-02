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
