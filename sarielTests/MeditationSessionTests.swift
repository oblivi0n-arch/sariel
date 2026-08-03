import Testing
import Foundation
@testable import sariel

struct MeditationSessionTests {

    @Test func actualDurationShorterThanPlannedCountsAsInterrupted() {
        let session = MeditationSession(intention: "spokój", plannedDuration: 600, actualDuration: 300)
        #expect(session.wasInterrupted == true)
    }

    @Test func actualDurationEqualToPlannedIsNotInterrupted() {
        let session = MeditationSession(intention: "spokój", plannedDuration: 600, actualDuration: 600)
        #expect(session.wasInterrupted == false)
    }

    @Test func actualDurationLongerThanPlannedIsNotInterrupted() {
        let session = MeditationSession(intention: "spokój", plannedDuration: 600, actualDuration: 900)
        #expect(session.wasInterrupted == false)
    }

    @Test func zeroActualDurationWithNonZeroPlannedCountsAsInterrupted() {
        let session = MeditationSession(intention: "spokój", plannedDuration: 600, actualDuration: 0)
        #expect(session.wasInterrupted == true)
    }
}
