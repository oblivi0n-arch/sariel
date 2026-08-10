import Testing
import Foundation
@testable import sariel

struct PinLockoutPolicyTests {

    @Test func noLockoutWithinFreeAttempts() {
        #expect(PinLockoutPolicy.lockoutDuration(after: 0) == 0)
        #expect(PinLockoutPolicy.lockoutDuration(after: 3) == 0)
    }

    @Test func lockoutEscalatesAfterFreeAttempts() {
        #expect(PinLockoutPolicy.lockoutDuration(after: 4) == 30)
        #expect(PinLockoutPolicy.lockoutDuration(after: 5) == 60)
        #expect(PinLockoutPolicy.lockoutDuration(after: 6) == 300)
        #expect(PinLockoutPolicy.lockoutDuration(after: 12) == 900)
    }

    @Test func noRemainingLockoutWithoutFailureDate() {
        #expect(PinLockoutPolicy.remainingLockout(failedAttempts: 6, lastFailureAt: nil) == 0)
    }

    @Test func remainingLockoutCountsDown() {
        let failedAt = Date()
        let now = failedAt.addingTimeInterval(10)

        let remaining = PinLockoutPolicy.remainingLockout(
            failedAttempts: 4, lastFailureAt: failedAt, now: now
        )

        #expect(remaining == 20)
    }

    @Test func lockoutExpiresExactlyAtBoundary() {
        let failedAt = Date()
        let now = failedAt.addingTimeInterval(30)

        let remaining = PinLockoutPolicy.remainingLockout(
            failedAttempts: 4, lastFailureAt: failedAt, now: now
        )

        #expect(remaining == 0)
    }

    @Test func clockMovedBackwardsDoesNotExtendLockout() {
        let failedAt = Date()
        let now = failedAt.addingTimeInterval(-3600)

        let remaining = PinLockoutPolicy.remainingLockout(
            failedAttempts: 4, lastFailureAt: failedAt, now: now
        )

        #expect(remaining == 30)
    }
}
