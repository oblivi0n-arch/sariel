import SwiftUI

enum VentPhase {
    case invitation
    case writing
    case burning
    case aftermath
}

struct VentView: View {
    @State private var phase: VentPhase = .invitation
    @State private var ventText: String = ""
    @State private var textBeingBurned: String = ""
    @State private var currentPrompt: String = VentTexts.prompts.randomElement()!
    @State private var currentAftermath: String = ""
    @FocusState private var isTextFocused: Bool
    
    private let characterLimit = 1000

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch phase {
            case .invitation:
                invitationView
            case .writing:
                writingView
            case .burning:
                BurningTextView(text: textBeingBurned, onFinished: handleBurnFinished)
            case .aftermath:
                aftermathView
            }
        }
    }

    private var invitationView: some View {
        VStack(spacing: 24) {
            Image(systemName: "flame")
                .font(.system(size: 32))
                .foregroundStyle(Theme.textFaint)

            Text(currentPrompt)
                .font(Theme.voiceFont)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            Button(action: startWriting) {
                Text("Start writing")
                    .font(Typography.label)
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.border, lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var writingView: some View {
        VStack {
            TextEditor(text: $ventText)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .focused($isTextFocused)
                .padding(20)
                .onChange(of: ventText) { _, newValue in
                    if newValue.count > characterLimit {
                        ventText = String(newValue.prefix(characterLimit))
                    }
                }
            
            Text("\(ventText.count) / \(characterLimit)")
                .font(Typography.caption)
                .foregroundStyle(ventText.count >= characterLimit ? Color.red.opacity(0.8) : Theme.textFaint)
                .padding(.horizontal, 20)

            Group {
                if ventText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("hold to burn")
                        .font(Typography.label)
                        .foregroundStyle(Theme.textFaint)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.border, lineWidth: 0.5)
                        )
                } else {
                    BurnHoldButton(onCommitted: beginBurning)
                }
            }
            .padding(.bottom, 30)
        }
        .overlay { vignetteOverlay }
        .onAppear { isTextFocused = true }
    }

    private var vignetteOverlay: some View {
        RadialGradient(
            colors: [Color.clear, Color.black.opacity(vignetteOpacity)],
            center: .center,
            startRadius: 80,
            endRadius: 420
        )
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.3), value: vignetteOpacity)
    }

    private var vignetteOpacity: Double {
        min(Double(ventText.count) / 350.0, 0.8)
    }

    private var aftermathView: some View {
        VStack(spacing: 20) {
            Text(currentAftermath)
                .font(Theme.voiceFont)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
        }
        .opacity(currentAftermath.isEmpty ? 0 : 1)
        .animation(.easeIn(duration: 0.5), value: currentAftermath)
        .overlay(alignment: .bottom) {
            if !currentAftermath.isEmpty {
                Button(action: reset) {
                    Text("okay")
                        .font(Typography.label)
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
        }
    }

    private func startWriting() {
        phase = .writing
    }

    private func beginBurning() {
        textBeingBurned = ventText
        ventText = ""
        phase = .burning
    }

    private func handleBurnFinished() {
        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            currentAftermath = VentTexts.aftermaths.randomElement()!
            phase = .aftermath
        }
    }

    private func reset() {
        currentPrompt = VentTexts.prompts.randomElement()!
        currentAftermath = ""
        textBeingBurned = ""
        phase = .invitation
    }
}
