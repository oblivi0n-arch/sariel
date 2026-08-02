import SwiftUI

struct MeditationBreathingView: View {
    let onComplete: () -> Void

    private let cycleCount = 3
    private let phaseDuration: TimeInterval = 4

    @State private var isInhaling = true
    @State private var breathTask: Task<Void, Never>?

    var body: some View {
        VStack {
            Spacer()

            Text(isInhaling ? L10n.MeditationBreathing.inhale : L10n.MeditationBreathing.exhale)
                .font(Typography.title)
                .foregroundStyle(Theme.textPrimary)
                .animation(.easeInOut(duration: phaseDuration), value: isInhaling)

            Spacer()

            Button(action: skip) {
                Text(L10n.MeditationBreathing.skip)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .onAppear { startSequence() }
        .onDisappear { breathTask?.cancel() }
    }

    private func startSequence() {
        breathTask = Task {
            for _ in 0..<cycleCount {
                guard !Task.isCancelled else { return }
                isInhaling = true
                try? await Task.sleep(nanoseconds: UInt64(phaseDuration * 1_000_000_000))

                guard !Task.isCancelled else { return }
                isInhaling = false
                try? await Task.sleep(nanoseconds: UInt64(phaseDuration * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            onComplete()
        }
    }

    private func skip() {
        breathTask?.cancel()
        onComplete()
    }
}

extension L10n {
    enum MeditationBreathing {
        static var inhale: String {
            switch lang {
            case .en: return "Breathe in"
            case .pl: return "Wdech"
            }
        }

        static var exhale: String {
            switch lang {
            case .en: return "Breathe out"
            case .pl: return "Wydech"
            }
        }

        static var skip: String {
            switch lang {
            case .en: return "Skip"
            case .pl: return "Pomiń"
            }
        }
    }
}
