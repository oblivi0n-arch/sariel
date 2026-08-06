import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext

    @Binding var activeEntry: JournalEntry?
    @ObservedObject private var themeManager = ThemeManager.shared
    
    let onOpenConversation: (Conversation) -> Void
    let achievementService: AchievementService

    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \JournalEntryTag.name) private var allTags: [JournalEntryTag]

    @State private var isPlusHovering = false
    @State private var isEditingEntry = false
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var searchText: String = ""
    @State private var isSearchExpanded = false
    @State private var isSearchHovering = false
    @State private var isArchiveHovering = false
    @State private var searchIncludesArchive = false
    @State private var isViewingArchive = false
    @FocusState private var isSearchFocused: Bool

    private var activeEntries: [JournalEntry] {
        entries.filter { !$0.isArchived }
    }

    private var archivedEntries: [JournalEntry] {
        entries.filter { $0.isArchived }
    }

    private func sortedByPriority(_ list: [JournalEntry]) -> [JournalEntry] {
        list.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    private var sortedActiveEntries: [JournalEntry] {
        sortedByPriority(activeEntries)
    }

    private var sortedArchivedEntries: [JournalEntry] {
        sortedByPriority(archivedEntries)
    }

    private var filteredEntries: [JournalEntry] {
        let source = searchIncludesArchive ? sortedByPriority(entries) : sortedActiveEntries
        var result = searchText.isEmpty ? sortedActiveEntries : source.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }

        if !selectedTagIDs.isEmpty {
            result = result.filter { entry in
                let entryTagIDs = Set(entry.tags.map { $0.id })
                return selectedTagIDs.isSubset(of: entryTagIDs)
            }
        }

        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !(activeEntry == nil && isViewingArchive) {
                HStack {
                    if activeEntry == nil, isSearchExpanded {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(Typography.iconButton)
                                .foregroundStyle(Theme.textFaint)

                            PlaceholderTextField(
                                placeholder: L10n.Journal.searchPlaceholder,
                                text: $searchText,
                                font: Typography.label,
                                textColor: Theme.textSecondary
                            )
                                .focused($isSearchFocused)

                            Button {
                                searchIncludesArchive.toggle()
                            } label: {
                                Image(systemName: "archivebox")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(searchIncludesArchive ? Theme.textPrimary : Theme.textFaint)
                            }
                            .buttonStyle(.plain)

                            Button(action: collapseSearch) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Theme.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
                    } else {
                        if activeEntry != nil {
                            BackButton(action: goBack)
                        }

                        Text(L10n.Journal.title)
                            .font(Typography.sectionTitle)
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        if activeEntry == nil {
                            Button {
                                isViewingArchive = true
                            } label: {
                                Image(systemName: "archivebox")
                                    .font(Typography.iconButton)
                                    .foregroundStyle(Theme.textMuted)
                                    .frame(width: 24, height: 24)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isArchiveHovering ? Theme.border : .clear, lineWidth: 1)
                                    )
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .trackHover($isArchiveHovering)

                            Button(action: expandSearch) {
                                Image(systemName: "magnifyingglass")
                                    .font(Typography.iconButton)
                                    .foregroundStyle(Theme.textMuted)
                                    .frame(width: 24, height: 24)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isSearchHovering ? Theme.border : .clear, lineWidth: 1)
                                    )
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .trackHover($isSearchHovering)

                            Button(action: createNewEntry) {
                                Image(systemName: "plus")
                                    .font(Typography.iconButton)
                                    .foregroundStyle(Theme.textMuted)
                                    .frame(width: 24, height: 24)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isPlusHovering ? Theme.border : .clear, lineWidth: 1)
                                    )
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .trackHover($isPlusHovering)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isSearchExpanded)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

                if activeEntry == nil, !allTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(allTags) { tag in
                                TagFilterChip(
                                    tag: tag,
                                    isSelected: selectedTagIDs.contains(tag.id),
                                    onToggle: { toggleTag(tag) }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 8)
                }
            }

            if let entry = activeEntry {
                JournalEntryDetailView(entry: entry, isEditing: $isEditingEntry, onOpenConversation: onOpenConversation, achievementService: achievementService)
            } else if isViewingArchive {
                JournalArchiveView(
                    entries: sortedArchivedEntries,
                    searchText: searchText,
                    onSelect: { entry in
                        activeEntry = entry
                        isEditingEntry = false
                    },
                    onDelete: { delete($0) },
                    onTogglePin: { togglePin($0) },
                    onUnarchive: { unarchive($0) },
                    onBack: { isViewingArchive = false }
                )
            } else if activeEntries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(filteredEntries) { entry in
                            JournalEntryRow(
                                entry: entry,
                                searchText: searchText,
                                onSelect: {
                                    activeEntry = entry
                                    isEditingEntry = false
                                },
                                onDelete: { delete(entry) },
                                onTogglePin: { togglePin(entry) },
                                onArchive: {
                                    if entry.isArchived {
                                        unarchive(entry)
                                    } else {
                                        archive(entry)
                                    }
                                }
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

    private func createNewEntry() {
        let new = JournalEntry()
        modelContext.insert(new)
        try? modelContext.save()
        activeEntry = new
        isEditingEntry = true
    }
    
    private func delete(_ entry: JournalEntry) {
        let tags = entry.tags
        modelContext.delete(entry)
        for tag in tags {
            JournalEntryTag.deleteIfOrphaned(tag, modelContext: modelContext)
        }
        try? modelContext.save()
    }
    
    private func togglePin(_ entry: JournalEntry) {
        entry.isPinned.toggle()
        try? modelContext.save()
    }

    private func archive(_ entry: JournalEntry) {
        entry.isArchived = true
        try? modelContext.save()
    }

    private func unarchive(_ entry: JournalEntry) {
        entry.isArchived = false
        try? modelContext.save()
    }
    
    private var emptyState: some View {
        VStack(spacing: 6) {
            Text(L10n.Journal.emptyStateTitle)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textMuted)

            Text(L10n.Journal.emptyStateSubtitle)
                .font(Typography.label)
                .foregroundStyle(Theme.textFaint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func goBack() {
        if let entry = activeEntry {
            let trimmedTitle = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let isEffectivelyEmpty = (trimmedTitle.isEmpty || L10n.Journal.allNewEntryTitleVariants.contains(trimmedTitle)) && entry.content.isEmpty
            if isEffectivelyEmpty {
                let tags = entry.tags
                modelContext.delete(entry)
                for tag in tags {
                    JournalEntryTag.deleteIfOrphaned(tag, modelContext: modelContext)
                }
                try? modelContext.save()
            }
        }
        activeEntry = nil
        isEditingEntry = false
    }
    
    private func expandSearch() {
        isSearchExpanded = true
        isSearchFocused = true
    }

    private func collapseSearch() {
        searchText = ""
        isSearchExpanded = false
        isSearchFocused = false
    }

    private func toggleTag(_ tag: JournalEntryTag) {
        if selectedTagIDs.contains(tag.id) {
            selectedTagIDs.remove(tag.id)
        } else {
            selectedTagIDs.insert(tag.id)
        }
    }
}

extension L10n {
    enum Journal {
        static var title: String {
            switch lang {
            case .en: return "Journal"
            case .pl: return "Dziennik"
            }
        }

        static var searchPlaceholder: String {
            switch lang {
            case .en: return "Search entries"
            case .pl: return "Szukaj wpisów"
            }
        }

        static var emptyStateTitle: String {
            switch lang {
            case .en: return "No entries yet"
            case .pl: return "Brak wpisów"
            }
        }

        static var emptyStateSubtitle: String {
            switch lang {
            case .en: return "Tap + to write your first one"
            case .pl: return "Dotknij +, aby napisać pierwszy wpis"
            }
        }

        static func newEntryTitle(for language: AppLanguage) -> String {
            switch language {
            case .en: return "New entry"
            case .pl: return "Nowy wpis"
            }
        }

        static var newEntryTitle: String { newEntryTitle(for: lang) }

        static var allNewEntryTitleVariants: [String] {
            AppLanguage.allCases.map { newEntryTitle(for: $0) }
        }
    }
}
