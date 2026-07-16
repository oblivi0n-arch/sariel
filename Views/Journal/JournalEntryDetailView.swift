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
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textFaint)

            HStack(spacing: 8) {
                Text(entry.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }

            Text(entry.content)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)

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
