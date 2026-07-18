import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.startedAt, order: .reverse) private var conversations: [Conversation]

    @State private var activeConversation: Conversation?
    @State private var isConversationListOpen = false
    @State private var isSettingsOpen = false
    @State private var selectedSection: AppSection = .chat
    @State private var activeEntry: JournalEntry?
    @StateObject private var chatService = ChatService()

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedSection: $selectedSection, isSettingsOpen: $isSettingsOpen)

            ZStack {
                Group {
                    switch selectedSection {
                    case .chat:
                        ZStack(alignment: .leading) {
                            Group {
                                if let conversation = activeConversation {
                                    ChatView(
                                        conversation: conversation,
                                        chatService: chatService,
                                        isConversationListOpen: $isConversationListOpen,
                                        onJournalEntryCreated: { entry in
                                            activeEntry = entry
                                            selectedSection = .journal
                                        },
                                        isActive: selectedSection == .chat

                                    )
                                    .id(conversation.id)
                                } else {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Theme.background)
                                }
                            }

                            if isConversationListOpen {
                                Color.black.opacity(0.5)
                                    .ignoresSafeArea()
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            isConversationListOpen = false
                                        }
                                    }

                                ConversationListView(
                                    conversations: conversations,
                                    activeConversation: $activeConversation,
                                    isConversationListOpen: $isConversationListOpen
                                )
                                    .transition(.move(edge: .leading))
                            }
                        }
                        .clipped()

                    case .journal:
                        JournalView(activeEntry: $activeEntry, onOpenConversation: openConversation)
                    }
                }

                if isSettingsOpen {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isSettingsOpen = false
                            }
                        }

                    Text("Settings")
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: 480, maxHeight: 400)
                        .background(Theme.fieldBackground)
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear(perform: setupConversation)
        .onChange(of: activeConversation) {
            if activeConversation == nil {
                setupConversation()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isConversationListOpen)
        .animation(.easeInOut(duration: 0.25), value: isSettingsOpen)
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
    
    private func openConversation(_ conversation: Conversation) {
        activeConversation = conversation
        selectedSection = .chat
    }
}
