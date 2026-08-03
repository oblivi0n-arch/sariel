import SwiftUI

struct OnboardingView: View {
    let isPostReset: Bool
    let onFinished: () -> Void
    
    @State private var currentIndex: Int = 0
    @State private var isButtonHovering = false
    @State private var isRevealComplete = false
    @State private var isContentVisible = false
    @State private var pauseTask: Task<Void, Never>?
    
    private var screens: [OnboardingScreen] {
        OnboardingScreen.screens(isPostReset: isPostReset)
    }
    
    private var currentScreen: OnboardingScreen {
        screens[currentIndex]
    }
    
    private var isLastScreen: Bool {
        currentIndex == screens.count - 1
    }
    
    private var pauseDuration: Double {
        currentScreen.pauseDuration
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Theme.background.ignoresSafeArea()
            
            ZStack {
                if isContentVisible {
                    VStack(spacing: 16) {
                        if currentScreen.revealsText {
                            RevealingText(
                                fullText: currentScreen.text,
                                font: Theme.voiceFont,
                                color: currentScreen.isEmphasized ? Color.red.opacity(0.7) : Theme.textPrimary,
                                onComplete: { isRevealComplete = true }
                            )
                            .id(currentScreen.id)
                        } else {
                            VStack(spacing: 8) {
                                if let title = currentScreen.title {
                                    Text(title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .tracking(2)
                                        .foregroundStyle(Color.red.opacity(0.7))
                                }

                                Text(currentScreen.text)
                                    .font(Theme.uiFont)
                                    .foregroundStyle(Theme.textPrimary)
                            }
                        }
                    }
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { startPause() }
            .onChange(of: currentIndex) { _, _ in startPause() }
            
            advanceButton
                .padding(24)
        }
    }
    
    private func startPause() {
        isRevealComplete = false
        isContentVisible = false
        pauseTask?.cancel()
        
        pauseTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(pauseDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.5)) {
                isContentVisible = true
                if !currentScreen.revealsText {
                    isRevealComplete = true
                }
            }

            if let autoDelay = currentScreen.autoAdvanceAfter {
                try? await Task.sleep(nanoseconds: UInt64(autoDelay * 1_000_000_000))
                guard !Task.isCancelled else { return }
                advance()
            }
        }
    }
    
    private var advanceButton: some View {
        Group {
            if currentScreen.autoAdvanceAfter == nil {
                Text(currentScreen.buttonLabel)
                    .font(Typography.label)
                    .foregroundStyle(isButtonHovering ? Theme.textPrimary : Theme.textMuted)
                    .onTapGesture(perform: advance)
                    .onHover { hovering in isButtonHovering = hovering }
                    .allowsHitTesting(isRevealComplete)
                    .opacity(isRevealComplete ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4), value: isRevealComplete)
            }
        }
    }
    
    private func advance() {
        if isLastScreen {
            onFinished()
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                isContentVisible = false
                isRevealComplete = false
                currentIndex += 1
            }
        }
    }
}
