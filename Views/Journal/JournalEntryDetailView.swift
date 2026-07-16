import SwiftUI

struct JournalEntryDetailView: View {
    @Bindable var entry: JournalEntry
    @Binding var isEditing: Bool
    let onOpenConversation: (Conversation) -> Void

    var body: some View {
        if isEditing {
            JournalEntryEditor(entry: entry)
        } else {
            JournalEntryReader(entry: entry, onEdit: { isEditing = true }, onOpenConversation: onOpenConversation)
        }
    }
}

struct JournalEntryReader: View {
    let entry: JournalEntry
    let onEdit: () -> Void
    let onOpenConversation: (Conversation) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: entry.entryMood.symbolName)
                .font(Typography.icon)
                .foregroundStyle(Theme.textFaint)

            HStack(spacing: 8) {
                Text(entry.title)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(Typography.iconButton)
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }

            Text(entry.content)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)
            
            if !entry.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(entry.tags) { tag in
                        Text("#\(tag.name)")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }

            if let conversation = entry.sourceConversation {
                Button(action: { onOpenConversation(conversation) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                        Text("View conversation")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
    }
}
