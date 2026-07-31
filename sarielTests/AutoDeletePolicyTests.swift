import Testing
import Foundation
@testable import sariel

struct AutoDeletePolicyTests {

    @Test func doesNotWipeWhenDisabled() {
        let now = Date()
        let longAgo = Calendar.current.date(byAdding: .day, value: -365, to: now)!

        let result = AutoDeletePolicy.shouldWipe(enabled: false, lastActive: longAgo, thresholdDays: 7, now: now)

        #expect(result == false)
    }

    @Test func doesNotWipeWithoutPreviousLastActiveDate() {
        let result = AutoDeletePolicy.shouldWipe(enabled: true, lastActive: nil, thresholdDays: 7, now: Date())

        #expect(result == false)
    }

    @Test func doesNotWipeBeforeThreshold() {
        let now = Date()
        let sixDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: now)!

        let result = AutoDeletePolicy.shouldWipe(enabled: true, lastActive: sixDaysAgo, thresholdDays: 7, now: now)

        #expect(result == false)
    }

    @Test func wipesExactlyAtThreshold() {
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        let result = AutoDeletePolicy.shouldWipe(enabled: true, lastActive: sevenDaysAgo, thresholdDays: 7, now: now)

        #expect(result == true)
    }

    @Test func wipesAfterThreshold() {
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!

        let result = AutoDeletePolicy.shouldWipe(enabled: true, lastActive: thirtyDaysAgo, thresholdDays: 30, now: now)

        #expect(result == true)
    }

    @Test func fallsBackToSafeDefaultWhenThresholdIsZero() {
        let now = Date()
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!

        let result = AutoDeletePolicy.shouldWipe(enabled: true, lastActive: twoDaysAgo, thresholdDays: 0, now: now)

        #expect(result == false)
    }
}
