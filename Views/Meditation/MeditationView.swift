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
            VStack(spacing: 8) {
                Text("Timer — wkrótce")
                    .font(Typography.title)
                Text("Intencja: \(intention.isEmpty ? "—" : intention)")
                Text("Czas: \(duration.displayName)")
            }
            .foregroundStyle(Theme.textFaint)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
        }
    }
}
