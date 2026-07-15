import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
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
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(conversations) { conversation in
                        let isActive = conversation.id == activeConversation?.id
                        
                        Text(conversation.title)
                            .font(Theme.uiFont)
                            .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(isActive ? Theme.surfaceElevated : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                activeConversation = conversation
                                isConversationListOpen = false
                            }
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
    
    private func createNewConversation() {
        let new = Conversation()
        modelContext.insert(new)
        try? modelContext.save()
        activeConversation = new
        isConversationListOpen = false
    }
}
