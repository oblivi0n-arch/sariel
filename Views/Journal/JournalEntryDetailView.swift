import SwiftUI

struct JournalEntryDetailView: View {
    @Bindable var entry: JournalEntry
    @Binding var isEditing: Bool

    var body: some View {
        if isEditing {
            JournalEntryEditor(entry: entry)
        } else {
            JournalEntryReader(entry: entry, onEdit: { isEditing = true })
        }
    }
}

struct JournalEntryReader: View {
    let entry: JournalEntry
    let onEdit: () -> Void

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
        }
        .padding(16)
    }
}
