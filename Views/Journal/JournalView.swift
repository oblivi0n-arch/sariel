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
    @FocusState private var isSearchFocused: Bool
    
    private var sortedEntries: [JournalEntry] {
        entries.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
    
    private var filteredEntries: [JournalEntry] {
        var result = sortedEntries
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
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
            HStack {
                if activeEntry == nil, isSearchExpanded {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textFaint)
                        
                        TextField(L10n.Journal.searchPlaceholder, text: $searchText)
                            .textFieldStyle(.plain)
                            .font(Typography.label)
                            .foregroundStyle(Theme.textSecondary)
                            .focused($isSearchFocused)
                        
                        Button(action: collapseSearch) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.fieldBackground)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
                } else {
                    if activeEntry != nil {
                        Button(action: goBack) {
                            Image(systemName: "chevron.left")
                                .font(Typography.iconButton)
                                .foregroundStyle(Theme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(L10n.Journal.title)
                        .font(Typography.sectionTitle)
                        .foregroundStyle(Theme.textPrimary)
                    
                    Spacer()
                    
                    if activeEntry == nil {
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
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            isSearchHovering = hovering
                        }
                        
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
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            isPlusHovering = hovering
                        }
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
            
            if let entry = activeEntry {
                JournalEntryDetailView(entry: entry, isEditing: $isEditingEntry, onOpenConversation: onOpenConversation, achievementService: achievementService)
            } else if entries.isEmpty {
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
                                onTogglePin: { togglePin(entry) }
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
