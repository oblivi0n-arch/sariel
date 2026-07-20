import SwiftUI
import SwiftData

struct JournalView: View {
    @State private var isPlusHovering = false
    @Environment(\.modelContext) private var modelContext
    @Binding var activeEntry: JournalEntry?
    @State private var isEditingEntry = false
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \JournalEntryTag.name) private var allTags: [JournalEntryTag]

    @State private var selectedTagIDs: Set<UUID> = []
    
    @State private var searchText: String = ""
    
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
    
    private var sortedEntries: [JournalEntry] {
        entries.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
    
    let onOpenConversation: (Conversation) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if activeEntry != nil {
                    Button(action: goBack) {
                        Image(systemName: "chevron.left")
                            .font(Typography.iconButton)
                            .foregroundStyle(Theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }

                Text("Journal")
                    .font(Typography.sectionTitle)
                    .foregroundStyle(Theme.textPrimary)
                
                if activeEntry == nil {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textFaint)

                        TextField("Search entries", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(Typography.label)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.fieldBackground)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
                    .frame(maxWidth: 180)
                }

                Spacer()

                if activeEntry == nil {
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
                JournalEntryDetailView(entry: entry, isEditing: $isEditingEntry, onOpenConversation: onOpenConversation)
            } else if entries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(filteredEntries) { entry in
                            JournalEntryRow(
                                entry: entry,
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
            Text("No entries yet")
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textMuted)

            Text("Tap + to write your first one")
                .font(Typography.label)
                .foregroundStyle(Theme.textFaint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func goBack() {
        if let entry = activeEntry {
            let trimmedTitle = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let isEffectivelyEmpty = (trimmedTitle.isEmpty || trimmedTitle == "New entry") && entry.content.isEmpty
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
    
    private func toggleTag(_ tag: JournalEntryTag) {
        if selectedTagIDs.contains(tag.id) {
            selectedTagIDs.remove(tag.id)
        } else {
            selectedTagIDs.insert(tag.id)
        }
    }
}
