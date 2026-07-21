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
    @State private var currentPrompt: String = VentTexts.prompts.randomElement()!
    @State private var currentAftermath: String = ""
    @FocusState private var isTextFocused: Bool

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch phase {
            case .invitation:
                invitationView
            case .writing:
                writingView
            case .burning:
                burningPlaceholder
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
        .onAppear { isTextFocused = true }
    }

    // Temporary placeholder
    private var burningPlaceholder: some View {
        Text("burning...")
            .foregroundStyle(Theme.textMuted)
            .onAppear {
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    finishBurning()
                }
            }
    }

    private var aftermathView: some View {
        VStack(spacing: 20) {
            Text(currentAftermath)
                .font(Theme.voiceFont)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            Button(action: reset) {
                Text("okay")
                    .font(Typography.label)
                    .foregroundStyle(Theme.textMuted)
            }
            .buttonStyle(.plain)
        }
    }

    private func startWriting() {
        phase = .writing
    }

    private func beginBurning() {
        phase = .burning
    }

    private func finishBurning() {
        currentAftermath = VentTexts.aftermaths.randomElement()!
        ventText = ""
        phase = .aftermath
    }

    private func reset() {
        currentPrompt = VentTexts.prompts.randomElement()!
        phase = .invitation
    }
}
