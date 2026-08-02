import SwiftUI

struct MeditationBreathingView: View {
    let onComplete: () -> Void
    
    private let cycleCount = 3
    private let inhaleDuration: TimeInterval = 4
    private let exhaleDuration: TimeInterval = 6
    
    @State private var isInhaling = false
    @State private var breathTask: Task<Void, Never>?
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Theme.textPrimary, lineWidth: 3)
                    .frame(width: 280, height: 280)
                
                Circle()
                    .fill(Theme.textPrimary)
                    .frame(width: 260, height: 260)
                    .scaleEffect(isInhaling ? 1.0 : 0.55)
                
                Text(isInhaling ? L10n.MeditationBreathing.inhale : L10n.MeditationBreathing.exhale)
                    .font(Typography.title)
                    .foregroundStyle(Theme.background)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.15), value: isInhaling)
            }
            
            Spacer()
            
            Button(action: skip) {
                Text(L10n.MeditationBreathing.skip)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)
                    .textCase(.uppercase)
                    .kerning(0.5)
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
                withAnimation(.easeInOut(duration: inhaleDuration)) {
                    isInhaling = true
                }
                try? await Task.sleep(nanoseconds: UInt64(inhaleDuration * 1_000_000_000))
                
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: exhaleDuration)) {
                    isInhaling = false
                }
                try? await Task.sleep(nanoseconds: UInt64(exhaleDuration * 1_000_000_000))
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
