import SwiftUI

struct ChatHeaderView: View {
    let title: String
    @Binding var isConversationListOpen: Bool
    let isEnded: Bool
    let isEndingConversation: Bool
    let endConversationError: String?
    let canEndConversation: Bool
    let isInputLocked: Bool
    let isConnected: Bool
    let onOpenSavedEntry: () -> Void
    let onRequestEndConversation: () -> Void

    @State private var isHoveringSavedPill = false

    var body: some View {
        HStack {
            Button(action: { isConversationListOpen.toggle() }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textMuted)
            }
            .buttonStyle(.plain)
            .opacity(isConversationListOpen ? 0 : 1)
            .disabled(isConversationListOpen)

            Text(title)
                .font(Typography.label)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .padding(.leading, 4)

            Spacer()

            if isEnded {
                Button(action: onOpenSavedEntry) {
                    statusPill(
                        icon: "checkmark.circle",
                        text: "Saved — tap to view",
                        color: isHoveringSavedPill ? Theme.textPrimary : Theme.textSecondary
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in isHoveringSavedPill = hovering }
            } else if !isConnected {
                statusPill(icon: "wifi.slash", text: "Offline", color: Theme.textMuted)
            } else if let error = endConversationError {
                Button(action: {
                    guard !isInputLocked else { return }
                    onRequestEndConversation()
                }) {
                    statusPill(icon: "exclamationmark.triangle.fill", text: "Tap to retry", color: Theme.textPrimary)
                }
                .buttonStyle(.plain)
                .help(error)
            } else if isEndingConversation {
                EndConversationLoadingBar()
                    .frame(width: 120)
                    .clipShape(Capsule())
            } else {
                Button(action: {
                    guard !isInputLocked && canEndConversation else { return }
                    onRequestEndConversation()
                }) {
                    statusPill(icon: "book.closed", text: "End conversation")
                }
                .buttonStyle(.plain)
                .opacity(canEndConversation ? 1 : 0.4)
                .help(canEndConversation ? "" : "conversation is too short to save")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.border).frame(height: 0.5)
        }
    }

    private func statusPill(icon: String, text: String, color: Color = Theme.textSecondary) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            Text(text)
                .font(Typography.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.fieldBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
    }
}
