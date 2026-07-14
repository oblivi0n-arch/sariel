import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    private var isGuide: Bool { message.messageRole == .guide }
    private var isError: Bool { isGuide && message.content.hasPrefix("⚠️") }
    private static let errorColor = Color(hex: "E24B4A")

    var body: some View {
        VStack(alignment: isGuide ? .leading : .trailing, spacing: 4) {
            Text(isError ? "błąd" : (isGuide ? "sariel" : "ty"))
                .font(.system(size: 11))
                .foregroundStyle(isError ? Self.errorColor : Theme.textMuted)

            if isError {
                errorBubble
            } else {
                Text(message.content.isEmpty ? "…" : message.content)
                    .font(isGuide ? Theme.voiceFont : Theme.uiFont)
                    .foregroundStyle(isGuide ? Theme.textPrimary : Theme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isGuide ? Theme.surface : Theme.surfaceElevated)
                    .clipShape(bubbleShape)
                    .overlay(alignment: .leading) {
                        if isGuide {
                            Rectangle().fill(Theme.accent).frame(width: 2)
                        }
                    }
            }
        }
        .frame(maxWidth: 420, alignment: isGuide ? .leading : .trailing)
        .frame(maxWidth: .infinity, alignment: isGuide ? .leading : .trailing)
    }

    private var errorBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Self.errorColor)

            Text(message.content.replacingOccurrences(of: "⚠️ ", with: ""))
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Self.errorColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Self.errorColor.opacity(0.4), lineWidth: 1))
    }

    private var bubbleShape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: isGuide ? 0 : 10,
            bottomLeadingRadius: 10,
            bottomTrailingRadius: 10,
            topTrailingRadius: isGuide ? 10 : 0
        )
    }
}
