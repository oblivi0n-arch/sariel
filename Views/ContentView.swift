import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.startedAt, order: .reverse) private var conversations: [Conversation]

    @State private var activeConversation: Conversation?
    @State private var isConversationListOpen = false

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()

            ZStack(alignment: .leading) {
                Group {
                    if let conversation = activeConversation {
                        ChatView(
                            conversation: conversation,
                            modelContext: modelContext,
                            isConversationListOpen: $isConversationListOpen
                        )
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Theme.background)
                    }
                }

                if isConversationListOpen {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isConversationListOpen = false
                            }
                        }

                    ConversationListView(conversations: conversations)
                        .transition(.move(edge: .leading))
                }
            }
            .clipped()
        }
        .background(Theme.background)
        .onAppear(perform: setupConversation)
        .animation(.easeInOut(duration: 0.25), value: isConversationListOpen)
    }

    private func setupConversation() {
        guard activeConversation == nil else { return }
        if let latest = conversations.first {
            activeConversation = latest
        } else {
            let new = Conversation()
            modelContext.insert(new)
            try? modelContext.save()
            activeConversation = new
        }
    }
}
