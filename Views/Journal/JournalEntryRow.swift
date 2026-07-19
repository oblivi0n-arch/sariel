import SwiftUI

struct JournalEntryRow: View {
    let entry: JournalEntry
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void

    @State private var isHovering = false
    
    private var isProvocationEntry: Bool {
        entry.tags.contains { $0.name.caseInsensitiveCompare("provocation") == .orderedSame }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: entry.entryMood.symbolName)
                    .font(Typography.iconSmall)
                    .foregroundStyle(Theme.textFaint)

                if isProvocationEntry {
                    Image(systemName: "eye")
                        .font(Typography.iconSmall)
                        .foregroundStyle(Theme.textFaint)
                }

                Text(entry.title)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                if entry.isPinned {
                    Image(systemName: "pin.fill")
                        .font(Typography.iconSmall)
                        .foregroundStyle(Theme.textFaint)
                }

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
                Text(entry.tags.sorted(by: { $0.name < $1.name }).map { "#\($0.name)" }.joined(separator: " "))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fieldBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovering ? Theme.borderStrong : Theme.border, lineWidth: 0.5)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Theme.textPrimary.opacity(entry.entryMood.accentOpacity))
                .frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
        .contextMenu {
            Button(action: onTogglePin) {
                Label(entry.isPinned ? "Unpin" : "Pin", systemImage: entry.isPinned ? "pin.slash" : "pin")
            }

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
