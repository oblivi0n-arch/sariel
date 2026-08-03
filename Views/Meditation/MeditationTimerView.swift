import SwiftUI

struct MeditationTimerView: View {
    let plannedDuration: TimeInterval
    let onComplete: (TimeInterval) -> Void
    
    @State private var totalSeconds: TimeInterval
    @State private var remainingAtCheckpoint: TimeInterval
    @State private var runStartDate: Date?
    @State private var remainingSeconds: TimeInterval
    @State private var isMenuShown = false
    @State private var isPaused = false
    @State private var tickTask: Task<Void, Never>?
    @State private var extendFeedback: String?
    @State private var extendFeedbackTask: Task<Void, Never>?
    @State private var hasInteractedWithCircle = false
    @State private var isHoveringCircle = false
    
    init(plannedDuration: TimeInterval, onComplete: @escaping (TimeInterval) -> Void) {
        self.plannedDuration = plannedDuration
        self.onComplete = onComplete
        _totalSeconds = State(initialValue: plannedDuration)
        _remainingAtCheckpoint = State(initialValue: plannedDuration)
        _runStartDate = State(initialValue: Date())
        _remainingSeconds = State(initialValue: plannedDuration)
    }
    
    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1 - (remainingSeconds / totalSeconds)
    }
    
    private func currentRemaining() -> TimeInterval {
        guard let runStartDate, !isPaused else { return remainingAtCheckpoint }
        let elapsed = Date().timeIntervalSince(runStartDate)
        return max(remainingAtCheckpoint - elapsed, 0)
    }
    
    private var timeText: String {
        let total = max(Int(remainingSeconds.rounded()), 0)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
    
    var body: some View {
        ZStack {
            AmbientRingsView(radii: [160, 220, 280])
            
            VStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Theme.border, lineWidth: 4)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Theme.textPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.2), value: progress)
                    
                    Text(timeText)
                        .font(.system(size: 56, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(width: 280, height: 280)
                .contentShape(Circle())
                .onTapGesture {
                    hasInteractedWithCircle = true
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isMenuShown.toggle()
                    }
                }
                .trackHover($isHoveringCircle)
                
                if !isMenuShown && !hasInteractedWithCircle {
                    Text(L10n.MeditationTimer.tapHint)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                        .textCase(.uppercase)
                        .kerning(0.5)
                        .padding(.top, 16)
                        .transition(.opacity)
                }
                
                if let extendFeedback {
                    Text(extendFeedback)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textMuted)
                        .padding(.top, 16)
                        .transition(.opacity)
                }
                
                Spacer()
                
                if isMenuShown {
                    timerMenu
                        .transition(.opacity.combined(with: .move(edge: .bottom)).combined(with: .scale(scale: 0.94, anchor: .bottom)))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .onAppear { startTicking() }
        .onDisappear {
            tickTask?.cancel()
            extendFeedbackTask?.cancel()
        }
    }
    
    private var timerMenu: some View {
        HStack(spacing: 24) {
            TimerMenuButton(icon: "plus", label: L10n.MeditationTimer.extend, action: { extend() })
            TimerMenuButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                label: isPaused ? L10n.MeditationTimer.resume : L10n.MeditationTimer.pause,
                action: togglePause
            )
            TimerMenuButton(icon: "xmark", label: L10n.MeditationTimer.end, action: endNow)
        }
        .padding(.bottom, 48)
    }
    
    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled else { return }
                
                let remaining = currentRemaining()
                remainingSeconds = remaining
                
                if !isPaused && remaining <= 0 {
                    onComplete(totalSeconds)
                    return
                }
            }
        }
    }
    
    private func togglePause() {
        if isPaused {
            runStartDate = Date()
            isPaused = false
        } else {
            remainingAtCheckpoint = currentRemaining()
            isPaused = true
        }
    }
    
    private func extend(by seconds: TimeInterval = 300) {
        if isPaused {
            remainingAtCheckpoint += seconds
        } else {
            remainingAtCheckpoint = currentRemaining() + seconds
            runStartDate = Date()
        }
        totalSeconds += seconds
        remainingSeconds = currentRemaining()
        showExtendFeedback()
    }
    
    private func endNow() {
        tickTask?.cancel()
        onComplete(totalSeconds - currentRemaining())
    }
    
    private func showExtendFeedback() {
        extendFeedbackTask?.cancel()
        withAnimation(.easeOut(duration: 0.15)) {
            extendFeedback = L10n.MeditationTimer.extendedFeedback
        }
        extendFeedbackTask = Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.25)) {
                extendFeedback = nil
            }
        }
    }
}

private struct TimerMenuButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(Typography.icon)
                Text(label)
                    .font(Typography.caption)
            }
            .foregroundStyle(isHovering ? Theme.textPrimary : Theme.textMuted)
            .frame(width: 64)
        }
        .buttonStyle(.plain)
        .trackHover($isHovering)
    }
}

extension L10n {
    enum MeditationTimer {
        static var extend: String {
            switch lang {
            case .en: return "+5 min"
            case .pl: return "+5 min"
            }
        }
        
        static var pause: String {
            switch lang {
            case .en: return "Pause"
            case .pl: return "Wstrzymaj"
            }
        }
        
        static var resume: String {
            switch lang {
            case .en: return "Resume"
            case .pl: return "Wznów"
            }
        }
        
        static var end: String {
            switch lang {
            case .en: return "End"
            case .pl: return "Zakończ"
            }
        }
        
        static var extendedFeedback: String {
            switch lang {
            case .en: return "+5 min added"
            case .pl: return "Dodano +5 min"
            }
        }
        
        static var tapHint: String {
            switch lang {
            case .en: return "Tap to pause"
            case .pl: return "Stuknij, aby wstrzymać"
            }
        }
    }
}
