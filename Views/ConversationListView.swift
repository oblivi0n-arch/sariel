import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    let conversations: [Conversation]
    @Binding var activeConversation: Conversation?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("conversations")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textMuted)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(conversations) { conversation in
                        Text(conversation.title)
                            .font(Theme.uiFont)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contextMenu {
                                Button(role: .destructive) {
                                    delete(conversation)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(width: 220)
        .frame(maxHeight: .infinity)
        .background(Theme.surface)
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
}
