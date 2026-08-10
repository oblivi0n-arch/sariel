import Foundation

enum PinLockoutPolicy {
    static let freeAttempts = 3

    static func lockoutDuration(after attempts: Int) -> TimeInterval {
        switch attempts {
        case ...freeAttempts: return 0
        case 4:  return 30
        case 5:  return 60
        case 6:  return 300
        default: return 900
        }
    }

    static func remainingLockout(
        failedAttempts: Int,
        lastFailureAt: Date?,
        now: Date = Date()
    ) -> TimeInterval {
        guard let lastFailureAt else { return 0 }

        let duration = lockoutDuration(after: failedAttempts)
        guard duration > 0 else { return 0 }

        let elapsed = now.timeIntervalSince(lastFailureAt)
        return min(duration, max(0, duration - elapsed))
    }
}

enum PinAttemptStore {
    private static let attemptsKey = "pinFailedAttempts"
    private static let lastFailureKey = "pinLastFailureAt"

    static var failedAttempts: Int {
        UserDefaults.standard.integer(forKey: attemptsKey)
    }

    static var lastFailureAt: Date? {
        UserDefaults.standard.object(forKey: lastFailureKey) as? Date
    }

    static var remainingLockout: TimeInterval {
        PinLockoutPolicy.remainingLockout(
            failedAttempts: failedAttempts,
            lastFailureAt: lastFailureAt
        )
    }

    static func recordFailure(at date: Date = Date()) {
        UserDefaults.standard.set(failedAttempts + 1, forKey: attemptsKey)
        UserDefaults.standard.set(date, forKey: lastFailureKey)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: attemptsKey)
        UserDefaults.standard.removeObject(forKey: lastFailureKey)
    }
}
