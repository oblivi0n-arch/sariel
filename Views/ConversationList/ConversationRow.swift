import SwiftUI

struct ConversationRow: View {
    let conversation: Conversation
    let isActive: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onRename: (String) -> Void

    @State private var isHovering = false
    @State private var isEditing = false
    @State private var editedTitle = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if isEditing {
                TextField("conversation title", text: $editedTitle)
                    .textFieldStyle(.plain)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textPrimary)
                    .focused($isFocused)
                    .onChange(of: isFocused) { oldValue, newValue in
                        if !newValue {
                            commitRename()
                        }
                    }
                    .onSubmit(commitRename)
            } else {
                Text(conversation.title)
                    .font(Theme.uiFont)
                    .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            if isEditing {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.border, lineWidth: 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                onSelect()
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button {
                startEditing()
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var backgroundColor: Color {
        if isEditing {
            return Theme.accent
        } else if isActive {
            return Theme.surfaceElevated
        } else if isHovering {
            return Theme.surfaceElevated.opacity(0.5)
        } else {
            return .clear
        }
    }

    private func startEditing() {
        editedTitle = conversation.title
        isEditing = true
        isFocused = true
    }

    private func commitRename() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onRename(trimmed)
        }
        isEditing = false
    }
}
