import SwiftUI

struct TribunalGateView: View {
    let pendingCount: Int
    let onFaceTribunal: () -> Void
    let onDismiss: () -> Void

    @State private var isDismissHovering = false
    @State private var isIconVisible = false
    @State private var isTitleStarted = false
    @State private var isRestVisible = false

    private var titleText: String {
        "The Tribunal awaits."
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "seal")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.red.opacity(0.85))
                    .opacity(isIconVisible ? 1 : 0)
                    .scaleEffect(isIconVisible ? 1 : 0.7)

                Group {
                    if isTitleStarted {
                        RevealingText(
                            fullText: titleText,
                            font: Theme.voiceFont,
                            color: Theme.textPrimary,
                            charsPerSecond: 30,
                            onComplete: { revealRest() }
                        )
                    } else {
                        Text(" ")
                            .font(Theme.voiceFont)
                    }
                }
                .multilineTextAlignment(.center)

                Group {
                    Text("\(pendingCount) commitment\(pendingCount == 1 ? "" : "s") await\(pendingCount == 1 ? "s" : "") trial. It will not go away on its own.")
                        .font(Typography.label)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)

                    Button(action: onFaceTribunal) {
                        Text("Face the Tribunal")
                            .font(Typography.label)
                            .foregroundStyle(Color.red.opacity(0.9))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.4), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)

                    Text("I'll avoid this a little longer")
                        .font(Typography.label)
                        .foregroundStyle(isDismissHovering ? Theme.textPrimary : Theme.textMuted)
                        .onTapGesture(perform: onDismiss)
                        .onHover { hovering in isDismissHovering = hovering }
                }
                .opacity(isRestVisible ? 1 : 0)
            }
            .frame(maxWidth: 380)
        }
        .onAppear { startSequence() }
    }

    private func startSequence() {
        withAnimation(.easeOut(duration: 0.5)) {
            isIconVisible = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            isTitleStarted = true
        }
    }

    private func revealRest() {
        withAnimation(.easeIn(duration: 0.4)) {
            isRestVisible = true
        }
    }
}
