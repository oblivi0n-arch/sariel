import SwiftUI

struct JournalArchiveView: View {
    let entries: [JournalEntry]
    let searchText: String
    let onSelect: (JournalEntry) -> Void
    let onDelete: (JournalEntry) -> Void
    let onTogglePin: (JournalEntry) -> Void
    let onUnarchive: (JournalEntry) -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                BackButton(action: onBack)

                Text(L10n.JournalArchive.title)
                    .font(Typography.sectionTitle)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if entries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(entries) { entry in
                            JournalEntryRow(
                                entry: entry,
                                searchText: searchText,
                                onSelect: { onSelect(entry) },
                                onDelete: { onDelete(entry) },
                                onTogglePin: { onTogglePin(entry) },
                                onArchive: { onUnarchive(entry) }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.background)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text(L10n.JournalArchive.emptyStateTitle)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension L10n {
    enum JournalArchive {
        static var title: String {
            switch lang {
            case .en: return "archive"
            case .pl: return "archiwum"
            }
        }

        static var emptyStateTitle: String {
            switch lang {
            case .en: return "No archived entries"
            case .pl: return "Brak zarchiwizowanych wpisów"
            }
        }
    }
}
