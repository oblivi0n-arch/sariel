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
        currentIndex == 0 ? 1.0 : 0.6
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Theme.background.ignoresSafeArea()
            
            ZStack {
                if isContentVisible {
                    VStack(spacing: 16) {
                        RevealingText(
                            fullText: currentScreen.text,
                            font: Theme.voiceFont,
                            color: Theme.textPrimary,
                            onComplete: { isRevealComplete = true }
                        )
                        .id(currentScreen.id)
                        .multilineTextAlignment(.center)
                        
                        if let footnote = currentScreen.footnote {
                            Text(footnote)
                                .font(Typography.caption)
                                .foregroundStyle(Theme.textFaint)
                                .italic()
                                .multilineTextAlignment(.center)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(currentIndex)
            .onAppear { startPause() }
            .onDisappear { pauseTask?.cancel() }
            
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
            .allowsHitTesting(isRevealComplete)
            .opacity(isRevealComplete ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: isRevealComplete)
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
            }
        }
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
