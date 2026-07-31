import Foundation

enum AutoDeletePolicy {
    static func shouldWipe(enabled: Bool, lastActive: Date?, thresholdDays: Int, now: Date) -> Bool {
        guard enabled else { return false }
        guard let lastActive else { return false }

        let effectiveThreshold = thresholdDays > 0 ? thresholdDays : AppLimits.autoDeleteThresholdOptions[0]
        let daysSinceLastActive = Calendar.current.dateComponents([.day], from: lastActive, to: now).day ?? 0

        return daysSinceLastActive >= effectiveThreshold
    }
}
