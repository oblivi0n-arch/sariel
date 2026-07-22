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
    @State private var isInfoShown = false
    @FocusState private var isTextFocused: Bool
    
    private let characterLimit = 1000
    
    private let ventSteps = [
        "This is where the thoughts eating you alive from the inside go — not the tidy version, the real one.",
        "Nothing you write here is saved. Not to this app, not anywhere. There's no draft to come back to.",
        "There's exactly one way out: burn it. No undo, no edit mid-burn, no saving it for later.",
        "The fire is just an animation. It doesn't do anything on its own — your belief in it does. Write like it matters, or don't bother.",
        "Hold back while you write, and you'll walk away carrying exactly what you walked in with."
    ]

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
        .overlay {
            if isInfoShown {
                infoOverlay
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isInfoShown)
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
            .hoverScale()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            Button(action: { isInfoShown = true }) {
                Image(systemName: "info.circle")
                    .font(Typography.icon)
                    .foregroundStyle(Theme.textMuted)
            }
            .buttonStyle(.plain)
            .padding(20)
            .hoverScale()
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
        .vignette(opacity: vignetteOpacity)
        .onAppear { isTextFocused = true }
    }

    private var vignetteOpacity: Double {
        min(Double(ventText.count) / 350.0, 0.8)
    }

    private var aftermathView: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(currentAftermath)
                .font(Theme.voiceFont)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            Spacer()

            if !currentAftermath.isEmpty {
                Button(action: reset) {
                    Text("okay")
                        .font(Typography.label)
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
                .hoverScale()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(currentAftermath.isEmpty ? 0 : 1)
        .animation(.easeIn(duration: 0.5), value: currentAftermath)
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
    
    private var infoOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { isInfoShown = false }

            VStack(alignment: .leading, spacing: 0) {
                infoHeader

                ScrollView {
                    explanationSteps
                        .padding(20)
                }
            }
            .frame(maxWidth: 420, maxHeight: 480)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.6), radius: 40, y: 12)
            .onTapGesture {}
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
    
    private var infoHeader: some View {
        HStack {
            Image(systemName: "flame")
                .font(Typography.icon)
                .foregroundStyle(Theme.textMuted)

            Text("vent")
                .font(Typography.title)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Button(action: { isInfoShown = false }) {
                Image(systemName: "xmark")
                    .font(Typography.iconButton)
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 24, height: 24)
                    .background(Theme.fieldBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .hoverScale()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.border).frame(height: 0.5)
        }
    }

    private var explanationSteps: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(ventSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(Typography.subsectionTitle)
                        .foregroundStyle(Theme.textFaint)
                        .frame(width: 20, alignment: .leading)

                    Text(step)
                        .font(Theme.uiFont)
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(3)
                }
            }
        }
    }
}

extension View {
    func vignette(opacity: Double) -> some View {
        overlay {
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(opacity)],
                center: .center,
                startRadius: 80,
                endRadius: 420
            )
            .allowsHitTesting(false)
        }
    }
}
