import SwiftUI

private enum MeditationStage {
    case setup
    case active(intention: String, duration: MeditationDuration)
}

struct MeditationView: View {
    @State private var stage: MeditationStage = .setup

    var body: some View {
        switch stage {
        case .setup:
            MeditationSetupView { intention, duration in
                stage = .active(intention: intention, duration: duration)
            }
        case .active(let intention, let duration):
            MeditationTimerView(plannedDuration: duration.seconds) { actualDuration in
                print("Sesja zakończona — intencja: \(intention), zaplanowano: \(duration.seconds)s, rzeczywiście: \(actualDuration)s")
                stage = .setup
            }
            .foregroundStyle(Theme.textFaint)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
        }
    }
}
