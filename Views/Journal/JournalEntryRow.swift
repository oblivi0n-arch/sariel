import SwiftUI

struct JournalEntryRow: View {
    let entry: JournalEntry
    let searchText: String
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void
    let onArchive: () -> Void

    @State private var isHovering = false
    
    private var isProvocationEntry: Bool {
        entry.tags.contains { tag in
            L10n.Provocation.allTagNameVariants.contains { tag.name.caseInsensitiveCompare($0) == .orderedSame }
        }
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

                HighlightedText(
                    text: entry.title,
                    searchText: searchText,
                    font: Typography.title,
                    baseColor: Theme.textPrimary
                )

                Spacer()

                if entry.isArchived {
                    Image(systemName: "archivebox")
                        .font(Typography.iconSmall)
                        .foregroundStyle(Theme.textFaint)
                }

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
                HighlightedText(
                    text: entry.content,
                    searchText: searchText,
                    font: Theme.uiFont,
                    baseColor: Theme.textSecondary
                )
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
        .trackHover($isHovering)
        .contextMenu {
            Button(action: onTogglePin) {
                Label(entry.isPinned ? L10n.JournalRow.unpin : L10n.JournalRow.pin, systemImage: entry.isPinned ? "pin.slash" : "pin")
            }

            Button(action: onArchive) {
                if entry.isArchived {
                    Label(L10n.JournalRow.unarchive, systemImage: "tray.and.arrow.up")
                } else {
                    Label(L10n.JournalRow.archive, systemImage: "archivebox")
                }
            }

            Button(role: .destructive, action: onDelete) {
                Label(L10n.JournalRow.delete, systemImage: "trash")
            }
        }
    }
}

extension L10n {
    enum JournalRow {
        static var unpin: String {
            switch lang {
            case .en: return "Unpin"
            case .pl: return "Odepnij"
            }
        }
        static var pin: String {
            switch lang {
            case .en: return "Pin"
            case .pl: return "Przypnij"
            }
        }
        static var delete: String {
            switch lang {
            case .en: return "Delete"
            case .pl: return "Usuń"
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
    }
}
