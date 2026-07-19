import SwiftUI

struct OnboardingView: View {
    let isPostReset: Bool
    let onFinished: () -> Void

    @State private var currentIndex: Int = 0
    @State private var isButtonHovering = false

    private var screens: [OnboardingScreen] {
        OnboardingScreen.screens(isPostReset: isPostReset)
    }

    private var currentScreen: OnboardingScreen {
        screens[currentIndex]
    }

    private var isLastScreen: Bool {
        currentIndex == screens.count - 1
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                RevealingText(
                    fullText: currentScreen.text,
                    font: Theme.voiceFont,
                    color: Theme.textPrimary
                )
                .multilineTextAlignment(.center)

                if let footnote = currentScreen.footnote {
                    Text(footnote)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                        .italic()
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(currentIndex)
            .transition(.opacity)

            advanceButton
                .padding(24)
        }
    }

    private var advanceButton: some View {
        Text(currentScreen.buttonLabel)
            .font(Typography.label)
            .foregroundStyle(isButtonHovering ? Theme.textPrimary : Theme.textMuted)
            .onTapGesture(perform: advance)
            .onHover { hovering in isButtonHovering = hovering }
    }

    private func advance() {
        if isLastScreen {
            onFinished()
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
            }
        }
    }
}
