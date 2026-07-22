import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isPlusHovering = false
    @State private var isSearchHovering = false
    @State private var isSearchExpanded = false
    @State private var searchText = ""
    @State private var blockedDeletionConversation: Conversation?
    @FocusState private var isSearchFocused: Bool
    let conversations: [Conversation]
    @Binding var activeConversation: Conversation?
    @Binding var isConversationListOpen: Bool
    @ObservedObject var chatService: ChatService
    
    private var filteredConversations: [Conversation] {
        guard !searchText.isEmpty else { return conversations }
        return conversations.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if isSearchExpanded {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textFaint)

                        TextField("Search conversations", text: $searchText)
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
                    Text("conversations")
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
                            }
                        )
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
                title: Text("Can't delete this conversation"),
                message: Text("It contains a declaration the Tribunal has tracked or ruled on. Deleting it would erase part of your accountability record."),
                dismissButton: .default(Text("OK"))
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
