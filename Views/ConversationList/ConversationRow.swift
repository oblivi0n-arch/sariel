import SwiftUI

struct ConversationRow: View {
    let conversation: Conversation
    let isActive: Bool
    let isGenerating: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onRename: (String) -> Void
    let onArchive: () -> Void
    
    @State private var isHovering = false
    @State private var isEditing = false
    @State private var editedTitle = ""
    @FocusState private var isFocused: Bool
    
    private var isEnded: Bool { conversation.journalEntry != nil }
    
    var body: some View {
        Group {
            if isEditing {
                TextField(L10n.ConversationRow.titlePlaceholder, text: $editedTitle)
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
                    
                    if conversation.containsCommitments {
                        Image(systemName: "seal.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textFaint)
                    }
                    
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
                Label(L10n.ConversationRow.rename, systemImage: "pencil")
            }
            Button(action: onArchive) {
                if conversation.isArchived {
                    Label(L10n.ConversationRow.unarchive, systemImage: "tray.and.arrow.up")
                } else {
                    Label(L10n.ConversationRow.archive, systemImage: "archivebox")
                }
            }
            Button(role: .destructive, action: onDelete) {
                Label(L10n.ConversationRow.delete, systemImage: "trash")
            }
            .disabled(isGenerating)
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

extension L10n {
    enum ConversationRow {
        static var titlePlaceholder: String {
            switch lang {
            case .en: return "conversation title"
            case .pl: return "tytuł rozmowy"
            }
        }
        
        static var rename: String {
            switch lang {
            case .en: return "Rename"
            case .pl: return "Zmień nazwę"
            }
        }
        
        static var archive: String {
            switch lang {
            case .en: return "Archive"
            case .pl: return "Archiwizuj"
            }
        }

        static var unarchive: String {
            switch lang {
            case .en: return "Restore from archive"
            case .pl: return "Przywróć z archiwum"
            }
        }
        
        static var delete: String {
            switch lang {
            case .en: return "Delete"
            case .pl: return "Usuń"
            }
        }
    }
}
