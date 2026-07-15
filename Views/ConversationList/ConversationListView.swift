import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isPlusHovering = false
    let conversations: [Conversation]
    @Binding var activeConversation: Conversation?
    @Binding var isConversationListOpen: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("conversations")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)

                Spacer()

                Button(action: createNewConversation) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
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
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(conversations) { conversation in
                        ConversationRow(
                            conversation: conversation,
                            isActive: conversation.id == activeConversation?.id,
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
    }

    private func delete(_ conversation: Conversation) {
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
}
