import SwiftUI

struct BurningTextView: View {
    let text: String
    let onFinished: () -> Void

    @State private var isBurning = false
    @State private var watchTask: Task<Void, Never>?

    private let charAnimationDuration: Double = 0.5

    private var characters: [Character] {
        Array(text)
    }

    private var perCharacterDelay: Double {
        guard !characters.isEmpty else { return 0 }
        return min(0.02, 1.8 / Double(characters.count))
    }

    private var totalDuration: Double {
        perCharacterDelay * Double(characters.count) + charAnimationDuration
    }

    var body: some View {
        ScrollView {
            FlowLayout(spacing: 0) {
                ForEach(Array(characters.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .font(Theme.uiFont)
                        .foregroundStyle(isBurning ? Color.red.opacity(0.85) : Theme.textPrimary)
                        .opacity(isBurning ? 0 : 1)
                        .scaleEffect(isBurning ? 0.7 : 1)
                        .animation(
                            .easeIn(duration: charAnimationDuration)
                                .delay(Double(index) * perCharacterDelay),
                            value: isBurning
                        )
                }
            }
            .padding(24)
        }
        .scrollDisabled(true)
        .onAppear {
            isBurning = true

            watchTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(totalDuration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                onFinished()
            }
        }
        .onDisappear {
            watchTask?.cancel()
        }
    }
}
