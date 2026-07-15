import SwiftUI

struct ConversationRow: View {
    let conversation: Conversation
    let isActive: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        Text(conversation.title)
            .font(Theme.uiFont)
            .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
            .onHover { hovering in
                isHovering = hovering
            }
            .contextMenu {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    private var backgroundColor: Color {
        if isActive {
            return Theme.surfaceElevated
        } else if isHovering {
            return Theme.surfaceElevated.opacity(0.5)
        } else {
            return .clear
        }
    }
}
