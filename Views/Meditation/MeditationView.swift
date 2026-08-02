import SwiftUI
import SwiftData

private enum MeditationStage {
    case setup
    case breathing(intention: String, duration: MeditationDuration)
    case active(intention: String, duration: MeditationDuration)
    case history
}

struct MeditationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeditationSession.createdAt, order: .reverse) private var sessions: [MeditationSession]
    @State private var stage: MeditationStage = .setup

    var body: some View {
        switch stage {
        case .setup:
            MeditationSetupView(
                onStart: { intention, duration in
                    stage = .breathing(intention: intention, duration: duration)
                },
                onShowHistory: { stage = .history }
            )
        case .breathing(let intention, let duration):
            MeditationBreathingView {
                stage = .active(intention: intention, duration: duration)
            }
        case .active(let intention, let duration):
            MeditationTimerView(plannedDuration: duration.seconds) { actualDuration in
                saveSession(intention: intention, plannedDuration: duration.seconds, actualDuration: actualDuration)
                stage = .setup
            }
        case .history:
            MeditationHistoryView(sessions: sessions, onBack: { stage = .setup })
        }
    }

    private func saveSession(intention: String, plannedDuration: TimeInterval, actualDuration: TimeInterval) {
        let session = MeditationSession(
            intention: intention,
            plannedDuration: plannedDuration,
            actualDuration: actualDuration
        )
        modelContext.insert(session)
        try? modelContext.save()
    }
}
