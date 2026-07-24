import SwiftUI
import SwiftData

struct ContentView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var systemColorScheme
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("isPostReset") private var isPostReset: Bool = false
    @AppStorage("lastActiveConversationID") private var lastActiveConversationIDString: String = ""
    @AppStorage("lastNotifiedCommitmentID") private var lastNotifiedCommitmentIDString: String = ""
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

        @Query(filter: #Predicate<Commitment> { $0.status == "pending" }, sort: \Commitment.createdAt)
        private var pendingCommitments: [Commitment]

        private var isTribunalInProgress: Bool {
            tribunalConversations.contains { $0.tribunalResolvedAt == nil }
        }

        private var isTribunalUnlocked: Bool {
            guard let oldest = pendingCommitments.first else { return false }
            return Date().timeIntervalSince(oldest.createdAt) >= Commitment.tribunalUnlockInterval
        }

    @State private var activeConversation: Conversation?
    @State private var isConversationListOpen = false
    @State private var isSettingsOpen = false
    @State private var selectedSection: AppSection = .chat
    @State private var activeEntry: JournalEntry?
    @State private var showSplash = true
    @State private var tribunalCheckTask: Task<Void, Never>?
    @State private var isGateShown = false
    @State private var hasEvaluatedGate = false
    @State private var isDimmed = false
    @StateObject private var chatService = ChatService()
    @StateObject private var toastManager = ToastManager()

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                SidebarView(
                    selectedSection: $selectedSection,
                    isSettingsOpen: $isSettingsOpen,
                    isTribunalLocked: isTribunalInProgress,
                    isTribunalAwaitingJudgment: isTribunalUnlocked,
                    onSelectSection: switchSection
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
                                            onDeclarationLimitBlocked: {
                                                toastManager.showDeclarationLimitBlocked()
                                            },
                                            onDeclarationEditBlocked: {
                                                toastManager.showDeclarationRequiresNewMessage()
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
                            TribunalView(chatService: chatService)
                        }
                    }
                    Color.black
                        .ignoresSafeArea()
                        .opacity(isDimmed ? 1 : 0)
                        .allowsHitTesting(isDimmed)
                    
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
                .background {
                    Button("") { switchSection(to: .chat) }
                        .keyboardShortcut("1", modifiers: .command)
                        .hidden()
                    Button("") { switchSection(to: .journal) }
                        .keyboardShortcut("2", modifiers: .command)
                        .hidden()
                    Button("") { switchSection(to: .tribunal) }
                        .keyboardShortcut("3", modifiers: .command)
                        .hidden()
                }
                .overlay(alignment: .topTrailing) {
                    VStack(alignment: .trailing, spacing: 8) {
                        ForEach(toastManager.toasts) { toast in
                            ToastView(toast: toast) {
                                switch toast.kind {
                                case .journalEntrySaved(let entry):
                                    activeEntry = entry
                                    selectedSection = .journal
                                case .tribunalUnlocked:
                                    selectedSection = .tribunal
                                case .declarationLimitBlocked:
                                    selectedSection = .tribunal
                                case .declarationRequiresNewMessage:
                                    break
                                }
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
            .onAppear {
                themeManager.updateSystemColorScheme(systemColorScheme)
            }
            .onChange(of: systemColorScheme) { _, newValue in
                themeManager.updateSystemColorScheme(newValue)
            }
            .onAppear {
                setupConversation()
                startTribunalUnlockChecking()
                evaluateTribunalGateIfNeeded()
                if isTribunalInProgress {
                    selectedSection = .tribunal
                }
            }
            .onChange(of: isTribunalUnlocked) { _, _ in
                evaluateTribunalGateIfNeeded()
            }
            .onChange(of: isTribunalInProgress) { _, _ in
                evaluateTribunalGateIfNeeded()
            }
            .onDisappear {
                tribunalCheckTask?.cancel()
            }
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
            } else if isGateShown {
                TribunalGateView(
                    pendingCount: pendingCommitments.count,
                    onFaceTribunal: {
                        isGateShown = false
                        selectedSection = .tribunal
                    },
                    onDismiss: {
                        isGateShown = false
                    }
                )
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
    
    private func checkTribunalUnlock() {
        var descriptor = FetchDescriptor<Commitment>(
            predicate: #Predicate<Commitment> { $0.status == "pending" },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        descriptor.fetchLimit = 1

        guard let oldest = try? modelContext.fetch(descriptor).first else { return }
        guard Date().timeIntervalSince(oldest.createdAt) >= Commitment.tribunalUnlockInterval else { return }
        guard lastNotifiedCommitmentIDString != oldest.id.uuidString else { return }

        // TODO: tribunal-unlocked toast is broken (fires incorrectly / needs rework) — re-enable once fixed
        // toastManager.showTribunalUnlocked()
        lastNotifiedCommitmentIDString = oldest.id.uuidString
    }
    
    private func startTribunalUnlockChecking() {
        tribunalCheckTask?.cancel()
        tribunalCheckTask = Task {
            while !Task.isCancelled {
                checkTribunalUnlock()
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 60s
            }
        }
    }
    
    private func evaluateTribunalGateIfNeeded() {
        guard !hasEvaluatedGate else { return }
        hasEvaluatedGate = true

        if isTribunalUnlocked && !isTribunalInProgress {
            isGateShown = true
        }
    }
    
    private func switchSection(to section: AppSection) {
        guard section != selectedSection else { return }

        withAnimation(.easeInOut(duration: 0.18)) {
            isDimmed = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            selectedSection = section
            withAnimation(.easeInOut(duration: 0.22)) {
                isDimmed = false
            }
        }
    }
}

extension L10n {
    enum Sections {
        static var chat: String {
            switch lang {
            case .en: return "Chat"
            case .pl: return "Czat"
            }
        }
        static var journal: String {
            switch lang {
            case .en: return "Journal"
            case .pl: return "Dziennik"
            }
        }
        static var tribunal: String {
            switch lang {
            case .en: return "Tribunal"
            case .pl: return "Trybunał"
            }
        }
    }
}
