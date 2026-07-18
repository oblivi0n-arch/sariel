import SwiftUI

struct JournalEntryRow: View {
    let entry: JournalEntry
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: entry.entryMood.symbolName)
                    .font(Typography.iconSmall)
                    .foregroundStyle(Theme.textFaint)

                Text(entry.title)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Text(entry.createdAt, style: .date)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
            }

            if !entry.content.isEmpty {
                Text(entry.content)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }

            if !entry.tags.isEmpty {
                Text(entry.tags.map { "#\($0.name)" }.joined(separator: " "))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovering ? Theme.borderStrong : Theme.border, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
