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
    
    private var isEnded: Bool { conversation.journalEntry != nil }

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
                HStack(spacing: 6) {
                    if conversation.isProvocation {
                        Image(systemName: "eye")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textFaint)
                    }
                    Text(conversation.title)
                        .font(Theme.uiFont)
                        .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)

                    Spacer(minLength: 0)

                    if isEnded {
                        Image(systemName: "book.closed")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textFaint)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isEditing ? Theme.fieldBackground : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: isEditing ? 1 : 0.5)
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

    private var borderColor: Color {
        if isEditing {
            return Theme.borderStrong
        } else if isActive {
            return Theme.borderStrong
        } else if isHovering {
            return Theme.border
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
