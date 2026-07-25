import Foundation

enum AchievementKind: String, CaseIterable {
    // MARK: - Behavioral / consistency
    case nightOwl              // writing between 00:00 and 04:00
    case consistencyStreak     // entries without a gap for X days
    case returnedAfterSilence  // came back after a long gap (21+ days)
    case writingSpiral         // several entries in a short time window

    // MARK: - Honesty / Commitment
    case commitmentsKept       // X kept commitments in a row
    case commitmentsBroken     // X broken commitments in a row
    case credibilityRecovered  // credibilityBand: .poor -> .solid
    case firstKeptAfterBroken  // first kept commitment after a broken streak

    // MARK: - Tribunal
    case tribunalFaced             // first time facing the tribunal
    case tribunalVerdictsAccepted  // number of uncomfortable verdicts accepted

    // MARK: - Thematic patterns
    case recurringTag          // same tag keeps reappearing across entries

    var symbolName: String {
        switch self {
        case .nightOwl: "moon.stars"
        case .consistencyStreak: "flame"
        case .returnedAfterSilence: "arrow.uturn.backward"
        case .writingSpiral: "tornado"
        case .commitmentsKept: "checkmark.seal"
        case .commitmentsBroken: "xmark.seal"
        case .credibilityRecovered: "arrow.up.right"
        case .firstKeptAfterBroken: "arrow.triangle.turn.up.right.diamond"
        case .tribunalFaced: "building.columns"
        case .tribunalVerdictsAccepted: "checkmark.shield"
        case .recurringTag: "repeat"
        }
    }

    var isProgressive: Bool {
        switch self {
        case .nightOwl: true
        case .consistencyStreak: true
        case .returnedAfterSilence: false
        case .writingSpiral: false
        case .commitmentsKept: true
        case .commitmentsBroken: true
        case .credibilityRecovered: false
        case .firstKeptAfterBroken: false
        case .tribunalFaced: false
        case .tribunalVerdictsAccepted: true
        case .recurringTag: true
        }
    }

    var targetCount: Int? {
        switch self {
        case .nightOwl: 7
        case .consistencyStreak: 14
        case .returnedAfterSilence: nil
        case .writingSpiral: nil
        case .commitmentsKept: 5
        case .commitmentsBroken: 3
        case .credibilityRecovered: nil
        case .firstKeptAfterBroken: nil
        case .tribunalFaced: nil
        case .tribunalVerdictsAccepted: 5
        case .recurringTag: 5
        }
    }
}
