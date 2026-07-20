import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("isPostReset") private var isPostReset: Bool = false
    @AppStorage("lastActiveConversationID") private var lastActiveConversationIDString: String = ""
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Conversation> { !$0.isTribunal },
        sort: \Conversation.startedAt,
        order: .reverse
    ) private var conversations: [Conversation]

    @Query(
        filter: #Predicate<Conversation> { $0.isTribunal },
        sort: \Conversation.startedAt,
        order: .reverse
    ) private var tribunalConversations: [Conversation]
    
    private var isTribunalInProgress: Bool {
        guard let activeConversation else { return false }
        return activeConversation.isTribunal && activeConversation.tribunalResolvedAt == nil
    }

    @State private var activeConversation: Conversation?
    @State private var isConversationListOpen = false
    @State private var isSettingsOpen = false
    @State private var selectedSection: AppSection = .chat
    @State private var activeEntry: JournalEntry?
    @State private var showSplash = true
    @StateObject private var chatService = ChatService()
    @StateObject private var toastManager = ToastManager()

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                SidebarView(
                    selectedSection: $selectedSection,
                    isSettingsOpen: $isSettingsOpen,
                    isTribunalLocked: isTribunalInProgress
                )
                
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
                                                toastManager.show(entry: entry)
                                            },
                                            onOpenJournalEntry: { entry in
                                                activeEntry = entry
                                                selectedSection = .journal
                                            },
                                            onBackToTribunal: {
                                                selectedSection = .tribunal
                                            },
                                            isActive: selectedSection == .chat
                                        )
                                        .id(conversation.id)
                                    } else {
                                        ProgressView()
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
                                    
                                    ConversationListView(
                                        conversations: conversations,
                                        activeConversation: $activeConversation,
                                        isConversationListOpen: $isConversationListOpen,
                                        chatService: chatService
                                    )
                                    .transition(.move(edge: .leading))
                                }
                            }
                            .clipped()
                            
                        case .journal:
                            JournalView(activeEntry: $activeEntry, onOpenConversation: openConversation)
                        
                        case .tribunal:
                            TribunalView(
                                chatService: chatService,
                                onTribunalStarted: { conversation in
                                    activeConversation = conversation
                                    selectedSection = .chat
                                },
                                onOpenConversation: openConversation
                            )
                        }
                    }
                    
                    if isSettingsOpen {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isSettingsOpen = false
                                }
                            }
                        
                        SettingsView(isPresented: $isSettingsOpen)
                            .frame(maxWidth: 560, maxHeight: 620)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
                            .shadow(color: .black.opacity(0.6), radius: 40, y: 12)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .overlay(alignment: .topTrailing) {
                    VStack(alignment: .trailing, spacing: 8) {
                        ForEach(toastManager.toasts) { toast in
                            ToastView(toast: toast) {
                                activeEntry = toast.entry
                                selectedSection = .journal
                                toastManager.dismiss(toast)
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(16)
                    .animation(.easeInOut(duration: 0.25), value: toastManager.toasts.map(\.id))
                }
            }
            .frame(minWidth: 760, minHeight: 660)
            .background(Theme.background.ignoresSafeArea())
            .onAppear(perform: setupConversation)
            .onChange(of: activeConversation) {
                if let activeConversation {
                    lastActiveConversationIDString = activeConversation.id.uuidString
                }
                if activeConversation == nil {
                    setupConversation()
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isConversationListOpen)
            .animation(.easeInOut(duration: 0.25), value: isSettingsOpen)
            
            if showSplash {
                SplashView {
                    showSplash = false
                }
            } else if !hasCompletedOnboarding {
                OnboardingView(isPostReset: isPostReset) {
                    hasCompletedOnboarding = true
                    isPostReset = false
                }
            }
        }
    }

    private func setupConversation() {
        guard activeConversation == nil else { return }

        if !lastActiveConversationIDString.isEmpty,
           let uuid = UUID(uuidString: lastActiveConversationIDString),
           let restored = fetchConversation(id: uuid) {
            activeConversation = restored
            return
        }

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
    
    private func fetchConversation(id: UUID) -> Conversation? {
        var descriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate<Conversation> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }
}
