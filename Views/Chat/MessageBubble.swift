import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    var showActions: Bool = false
    var onDelete: (() -> Void)? = nil
    var showRewind: Bool = false
    var onRewind: (() -> Void)? = nil
    
    @State private var isHovering = false

    private var isGuide: Bool { message.messageRole == .guide }
    private var isError: Bool { isGuide && message.content.hasPrefix("⚠️") }

    var body: some View {
        VStack(alignment: isGuide ? .leading : .trailing, spacing: 4) {
            Text(isError ? "error" : (isGuide ? "sariel" : "you"))
                .font(Typography.caption)
                .foregroundStyle(isError ? Theme.textPrimary : Theme.textMuted)

            if isError {
                errorBubble
            } else {
                Text(message.content.isEmpty ? "…" : message.content)
                    .font(isGuide ? Theme.voiceFont : Theme.uiFont)
                    .foregroundStyle(isGuide ? Theme.textPrimary : Theme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .clipShape(bubbleShape)
                    .overlay(bubbleShape.stroke(Theme.border, lineWidth: 0.5))
                    .overlay(alignment: .leading) {
                        if isGuide {
                            Rectangle().fill(Theme.borderStrong).frame(width: 2)
                        }
                    }
            }
        }
        .frame(maxWidth: 420, alignment: isGuide ? .leading : .trailing)
        .frame(maxWidth: .infinity, alignment: isGuide ? .leading : .trailing)
        .padding(.bottom, isGuide ? 0 : 22)
        .overlay(alignment: isGuide ? .bottomLeading : .bottomTrailing) {
            if isHovering {
                if showActions, let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                } else if showRewind, let onRewind {
                    Button(action: onRewind) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                }
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in isHovering = hovering }
    }

    private var errorBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Typography.label)
                .foregroundStyle(Theme.textPrimary)

            Text(message.content.replacingOccurrences(of: "⚠️ ", with: ""))
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.borderStrong, lineWidth: 1))
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
