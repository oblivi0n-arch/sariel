import SwiftUI
import SwiftData

private enum MeditationStage {
    case setup
    case breathing(intention: String, duration: MeditationDuration)
    case active(intention: String, duration: MeditationDuration)
    case finished(session: MeditationSession)
}

struct MeditationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeditationSession.createdAt, order: .reverse) private var sessions: [MeditationSession]
    @State private var stage: MeditationStage = .setup
    
    let achievementService: AchievementService

    var body: some View {
        switch stage {
        case .setup:
            MeditationSetupView(
                sessions: sessions,
                onStart: { intention, duration in
                    stage = .breathing(intention: intention, duration: duration)
                }
            )
        case .breathing(let intention, let duration):
            MeditationBreathingView {
                stage = .active(intention: intention, duration: duration)
            }
        case .active(let intention, let duration):
            MeditationTimerView(plannedDuration: duration.seconds) { actualDuration in
                let session = saveSession(intention: intention, plannedDuration: duration.seconds, actualDuration: actualDuration)
                stage = .finished(session: session)
            }
        case .finished(let session):
            MeditationCompletionView(session: session) {
                stage = .setup
            }
        }
    }

    @discardableResult
    private func saveSession(intention: String, plannedDuration: TimeInterval, actualDuration: TimeInterval) -> MeditationSession {
        let session = MeditationSession(
            intention: intention,
            plannedDuration: plannedDuration,
            actualDuration: actualDuration
        )
        modelContext.insert(session)
        try? modelContext.save()
        
        achievementService.checkMeditationConsistency(modelContext: modelContext)
        achievementService.checkMeditationAbandonedPattern(modelContext: modelContext)
        achievementService.checkMeditationFirstFullSession(modelContext: modelContext)
        
        return session
    }
}
