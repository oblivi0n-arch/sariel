import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext

    let conversations: [Conversation]
    @Binding var activeConversation: Conversation?
    @Binding var isConversationListOpen: Bool
    @ObservedObject var chatService: ChatService
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var isPlusHovering = false
    @State private var isSearchHovering = false
    @State private var isSearchExpanded = false
    @State private var searchText = ""
    @State private var blockedDeletionConversation: Conversation?
    @State private var isArchiveExpanded = false
    @State private var searchIncludesArchive = false
    @FocusState private var isSearchFocused: Bool

    private var filteredConversations: [Conversation] {
        let source = searchIncludesArchive ? conversations : activeConversations
        guard !searchText.isEmpty else { return activeConversations }
        return source.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var archiveToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isArchiveExpanded.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Text(L10n.ConversationList.archiveToggle)
                Image(systemName: isArchiveExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .medium))
            }
            .font(Typography.label)
            .foregroundStyle(Theme.textFaint)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var activeConversations: [Conversation] {
        conversations.filter { !$0.isArchived }
    }

    private var archivedConversations: [Conversation] {
        conversations.filter { $0.isArchived }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if isSearchExpanded {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textFaint)

                        PlaceholderTextField(
                            placeholder: L10n.ConversationList.searchPlaceholder,
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
                    .background(Theme.fieldBackground)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
                } else {
                    Text(L10n.ConversationList.title)
                        .font(Typography.subsectionTitle)
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

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

                    Button(action: createNewConversation) {
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
            .animation(.easeInOut(duration: 0.2), value: isSearchExpanded)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredConversations) { conversation in
                        ConversationRow(
                            conversation: conversation,
                            isActive: conversation.id == activeConversation?.id,
                            isGenerating: chatService.generatingConversationIDs.contains(conversation.id),
                            searchText: searchText,
                            onSelect: {
                                activeConversation = conversation
                                isConversationListOpen = false
                            },
                            onDelete: {
                                delete(conversation)
                            },
                            onRename: { newTitle in
                                conversation.title = newTitle
                                try? modelContext.save()
                            },
                            onArchive: {
                                if conversation.isArchived {
                                    unarchive(conversation)
                                } else {
                                    archive(conversation)
                                }
                            }
                        )
                    }
                }
                
                if !archivedConversations.isEmpty {
                    archiveToggle

                    if isArchiveExpanded {
                        ForEach(archivedConversations) { conversation in
                            ConversationRow(
                                conversation: conversation,
                                isActive: conversation.id == activeConversation?.id,
                                isGenerating: false,
                                searchText: searchText,
                                onSelect: {
                                    activeConversation = conversation
                                    isConversationListOpen = false
                                },
                                onDelete: { delete(conversation) },
                                onRename: { _ in },
                                onArchive: { unarchive(conversation) }
                            )
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(width: 220)
        .frame(maxHeight: .infinity)
        .background(Theme.background)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Theme.border).frame(width: 0.5)
        }
        .alert(item: $blockedDeletionConversation) { conversation in
            Alert(
                title: Text(L10n.ConversationList.deleteBlockedTitle),
                message: Text(L10n.ConversationList.deleteBlockedMessage),
                dismissButton: .default(Text(L10n.ConversationList.ok))
            )
        }
    }

    private func delete(_ conversation: Conversation) {
        guard !conversation.containsCommitments else {
            blockedDeletionConversation = conversation
            return
        }
        if activeConversation?.id == conversation.id {
            activeConversation = conversations.first { $0.id != conversation.id }
        }
        modelContext.delete(conversation)
        try? modelContext.save()
    }
    
    private func archive(_ conversation: Conversation) {
        conversation.isArchived = true
        if activeConversation?.id == conversation.id {
            activeConversation = activeConversations.first
        }
        try? modelContext.save()
    }

    private func unarchive(_ conversation: Conversation) {
        conversation.isArchived = false
        try? modelContext.save()
    }

    private func createNewConversation() {
        let new = Conversation()
        modelContext.insert(new)
        try? modelContext.save()
        activeConversation = new
        isConversationListOpen = false
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
}

extension L10n {
    enum ConversationList {
        static var searchPlaceholder: String {
            switch lang {
            case .en: return "Search conversations"
            case .pl: return "Szukaj rozmów"
            }
        }

        static var title: String {
            switch lang {
            case .en: return "conversations"
            case .pl: return "rozmowy"
            }
        }

        static var deleteBlockedTitle: String {
            switch lang {
            case .en: return "Can't delete this conversation"
            case .pl: return "Nie można usunąć tej rozmowy"
            }
        }

        static var deleteBlockedMessage: String {
            switch lang {
            case .en: return "It contains a declaration the Tribunal has tracked or ruled on. Deleting it would erase part of your accountability record."
            case .pl: return "Zawiera deklarację, którą Trybunał śledził lub co do której wydał wyrok. Usunięcie jej wymazałoby część Twojej historii odpowiedzialności."
            }
        }

        static var ok: String {
            switch lang {
            case .en: return "OK"
            case .pl: return "OK"
            }
        }
        
        static var archiveToggle: String {
            switch lang {
            case .en: return "archive"
            case .pl: return "archiwum"
            }
        }
    }
}
