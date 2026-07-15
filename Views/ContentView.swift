import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.startedAt, order: .reverse) private var conversations: [Conversation]

    @State private var activeConversation: Conversation?

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()

            Group {
                if let conversation = activeConversation {
                    ChatView(conversation: conversation, modelContext: modelContext)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.background)
                }
            }
        }
        .onAppear(perform: setupConversation)
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
