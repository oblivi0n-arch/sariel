import SwiftUI

struct JournalEntryRow: View {
    let entry: JournalEntry
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: entry.entryMood.symbolName)
                .font(Typography.iconSmall)
                .foregroundStyle(Theme.textFaint)

            Text(entry.title)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)
            
            if !entry.tags.isEmpty {
                Text(entry.tags.map { "#\($0.name)" }.joined(separator: " "))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
                    .lineLimit(1)
            }

            Spacer()

            Text(entry.createdAt, style: .date)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovering ? Theme.fieldBackground : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
