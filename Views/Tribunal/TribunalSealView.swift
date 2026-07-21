import SwiftUI

struct TribunalSealBanner: View {
    let isDocked: Bool

    @State private var isIconVisible = false
    @State private var isTextStarted = false

    private let message = "Once it leaves your draft, it's sealed. No edits. No rewinds."

    var body: some View {
        VStack(spacing: isDocked ? 6 : 12) {
            Image(systemName: "seal.fill")
                .font(.system(size: isDocked ? 13 : 30))
                .foregroundStyle(Color.red.opacity(0.8))
                .opacity(isIconVisible ? 1 : 0)
                .scaleEffect(isIconVisible ? 1 : 0.6)

            if isDocked {
                Text(message)
                    .font(Typography.caption)
                    .foregroundStyle(Color.red.opacity(0.75))
            } else {
                Group {
                    if isTextStarted {
                        RevealingText(fullText: message, font: Typography.label, color: Color.red.opacity(0.8), charsPerSecond: 40)
                    } else {
                        Text(" ").font(Typography.label)
                    }
                }
                .multilineTextAlignment(.center)
            }
        }
        .padding(isDocked ? EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16)
                          : EdgeInsets(top: 24, leading: 30, bottom: 24, trailing: 30))
        .background(isDocked ? Color.clear : Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: isDocked ? 0 : 12))
        .overlay {
            if !isDocked {
                RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.4), lineWidth: 0.5)
            }
        }
        .onAppear {
            guard !isDocked else {
                isIconVisible = true
                return
            }
            withAnimation(.easeOut(duration: 0.4)) { isIconVisible = true }
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                isTextStarted = true
            }
        }
    }
}
