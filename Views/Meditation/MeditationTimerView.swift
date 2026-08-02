import SwiftUI

struct MeditationTimerView: View {
    let plannedDuration: TimeInterval
    let onComplete: (TimeInterval) -> Void
    
    @State private var remainingSeconds: TimeInterval
    @State private var totalSeconds: TimeInterval
    @State private var isMenuShown = false
    @State private var isPaused = false
    @State private var tickTask: Task<Void, Never>?
    
    init(plannedDuration: TimeInterval, onComplete: @escaping (TimeInterval) -> Void) {
        self.plannedDuration = plannedDuration
        self.onComplete = onComplete
        _remainingSeconds = State(initialValue: plannedDuration)
        _totalSeconds = State(initialValue: plannedDuration)
    }
    
    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1 - (remainingSeconds / totalSeconds)
    }
    
    private var elapsedSeconds: TimeInterval {
        totalSeconds - remainingSeconds
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
                        .stroke(Theme.border, lineWidth: 2)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Theme.textPrimary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text(timeText)
                        .font(.system(size: 56, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(width: 280, height: 280)
                .contentShape(Circle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isMenuShown.toggle()
                    }
                }
                
                Spacer()
                
                if isMenuShown {
                    timerMenu
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .onAppear { startTicking() }
        .onDisappear { tickTask?.cancel() }
    }
    
    private var timerMenu: some View {
        HStack(spacing: 24) {
            menuButton(icon: "plus", label: L10n.MeditationTimer.extend, action: { extend() })
            menuButton(
                icon: isPaused ? "play.fill" : "pause.fill",
                label: isPaused ? L10n.MeditationTimer.resume : L10n.MeditationTimer.pause,
                action: { isPaused.toggle() }
            )
            menuButton(icon: "xmark", label: L10n.MeditationTimer.end, action: endNow)
        }
        .padding(.bottom, 48)
    }
    
    private func menuButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(Typography.icon)
                Text(label)
                    .font(Typography.caption)
            }
            .foregroundStyle(Theme.textMuted)
            .frame(width: 64)
        }
        .buttonStyle(.plain)
    }
    
    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                
                if !isPaused {
                    remainingSeconds = max(remainingSeconds - 1, 0)
                    if remainingSeconds == 0 {
                        onComplete(totalSeconds)
                        return
                    }
                }
            }
        }
    }
    
    private func extend(by seconds: TimeInterval = 300) -> Void {
        remainingSeconds += seconds
        totalSeconds += seconds
    }
    
    private func endNow() {
        tickTask?.cancel()
        onComplete(elapsedSeconds)
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
    }
}
