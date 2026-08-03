import SwiftUI
import SwiftData

struct ContentView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("selectedSection") private var selectedSection: AppSection = .chat
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("isPostReset") private var isPostReset: Bool = false
    @AppStorage("lastActiveConversationID") private var lastActiveConversationIDString: String = ""
    @AppStorage("lastDashboardShownDate") private var lastDashboardShownDateString: String = ""
    @AppStorage("appLockEnabled") private var appLockEnabled: Bool = false
    @AppStorage(ShortcutAction.dashboard.storageKey) private var dashboardShortcut = ShortcutAction.dashboard.defaultShortcut
    @AppStorage(ShortcutAction.chat.storageKey) private var chatShortcut = ShortcutAction.chat.defaultShortcut
    @AppStorage(ShortcutAction.journal.storageKey) private var journalShortcut = ShortcutAction.journal.defaultShortcut
    @AppStorage(ShortcutAction.tribunal.storageKey) private var tribunalShortcut = ShortcutAction.tribunal.defaultShortcut
    @AppStorage(ShortcutAction.meditation.storageKey) private var meditationShortcut = ShortcutAction.meditation.defaultShortcut
    
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
    
    @State private var activeConversation: Conversation?
    @State private var isConversationListOpen = false
    @State private var isSettingsOpen = false
    @State private var activeEntry: JournalEntry?
    @State private var showSplash = true
    @State private var hasEnteredApp = false
    @State private var isGateShown = false
    @State private var hasEvaluatedGate = false
    @State private var isDimmed = false
    @State private var hasFinishedNarrativeOnboarding = false
    @State private var isUnlocked = false
    @StateObject private var chatService = ChatService()
    @StateObject private var toastManager = ToastManager()
    @StateObject private var achievementService = AchievementService()
    
    private var isTribunalInProgress: Bool {
        tribunalConversations.contains { $0.tribunalResolvedAt == nil }
    }
    
    private var isTribunalUnlocked: Bool {
        guard let oldest = pendingCommitments.first else { return false }
        return Date().timeIntervalSince(oldest.createdAt) >= Commitment.tribunalUnlockInterval
    }
    
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
                        case .dashboard:
                            DashboardView(toastManager: toastManager, achievementService: achievementService)
                            
                        case .chat:
                            ZStack(alignment: .leading) {
                                Group {
                                    if let conversation = activeConversation {
                                        chatSectionView(for: conversation)
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
                            JournalView(activeEntry: $activeEntry, onOpenConversation: openConversation, achievementService: achievementService)
                            
                        case .tribunal:
                            TribunalView(
                                chatService: chatService,
                                achievementService: achievementService,
                                onOpenConversation: openConversation
                            )
                        case .meditation:
                            MeditationView(achievementService: achievementService)
                        }
                    }
                    Theme.background
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
                        
                        SettingsView(isPresented: $isSettingsOpen, onStartAcquaintance: startAcquaintanceFromSettings)
                            .frame(maxWidth: 560, maxHeight: 620)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
                            .shadow(color: .black.opacity(0.6), radius: 40, y: 12)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .background {
                    Button("") { switchSection(to: .dashboard) }
                        .keyboardShortcut(dashboardShortcut.keyEquivalent, modifiers: dashboardShortcut.eventModifiers)
                        .hidden()
                    Button("") { switchSection(to: .chat) }
                        .keyboardShortcut(chatShortcut.keyEquivalent, modifiers: chatShortcut.eventModifiers)
                        .hidden()
                    Button("") { switchSection(to: .journal) }
                        .keyboardShortcut(journalShortcut.keyEquivalent, modifiers: journalShortcut.eventModifiers)
                        .hidden()
                    Button("") { switchSection(to: .tribunal) }
                        .keyboardShortcut(tribunalShortcut.keyEquivalent, modifiers: tribunalShortcut.eventModifiers)
                        .hidden()
                    Button("") { switchSection(to: .meditation) }
                        .keyboardShortcut(meditationShortcut.keyEquivalent, modifiers: meditationShortcut.eventModifiers)
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
                                case .declarationLimitBlocked:
                                    selectedSection = .tribunal
                                case .declarationRequiresNewMessage:
                                    break
                                case .achievementUnlocked:
                                    selectedSection = .dashboard
                                case .selfLetterAvailable:
                                    selectedSection = .dashboard
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
            .opacity(hasEnteredApp ? 1 : 0)
            .scaleEffect(hasEnteredApp ? 1 : 0.97)
            .background(Theme.background.ignoresSafeArea())
            .onAppear {
                themeManager.updateSystemColorScheme(systemColorScheme)
            }
            .onChange(of: systemColorScheme) { _, newValue in
                themeManager.updateSystemColorScheme(newValue)
            }
            .onAppear {
                setupConversation()
                evaluateTribunalGateIfNeeded()
                showDashboardOnNewDay()
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
            .onChange(of: activeConversation) {
                if let activeConversation {
                    lastActiveConversationIDString = activeConversation.id.uuidString
                }
                if activeConversation == nil {
                    setupConversation()
                }
            }
            .onChange(of: achievementService.newlyUnlocked) { _, newValue in
                if let newValue {
                    toastManager.showAchievementUnlocked(newValue)
                    achievementService.newlyUnlocked = nil
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isConversationListOpen)
            .animation(.easeInOut(duration: 0.25), value: isSettingsOpen)
            
            if showSplash && hasCompletedOnboarding {
                SplashView {
                    withAnimation(.easeOut(duration: 0.6)) {
                        showSplash = false
                        hasEnteredApp = true
                    }
                }
                .transition(.opacity)
            } else if appLockEnabled && !isUnlocked {
                PinUnlockView {
                    isUnlocked = true
                }
            } else if !hasCompletedOnboarding {
                if !hasCompletedOnboarding {
                    if !hasFinishedNarrativeOnboarding {
                        OnboardingView(isPostReset: isPostReset) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                hasFinishedNarrativeOnboarding = true
                            }
                        }
                        .transition(.opacity)
                    } else {
                        SetupWizardView {
                            hasCompletedOnboarding = true
                            isPostReset = false
                            withAnimation(.easeOut(duration: 0.6)) {
                                hasEnteredApp = true
                            }
                        }
                        .transition(.opacity)
                    }
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
        .environment(\.colorScheme, themeManager.resolved.baseColorScheme)
    }
    
    private func setupConversation() {
        guard activeConversation == nil else { return }
        
        if !lastActiveConversationIDString.isEmpty,
           let uuid = UUID(uuidString: lastActiveConversationIDString),
           let restored = fetchConversation(id: uuid) {
            activeConversation = restored
            return
        }
        
        if let latest = conversations.first(where: { !$0.isArchived }) {
            activeConversation = latest
        } else {
            let new = Conversation()
            modelContext.insert(new)
            try? modelContext.save()
            activeConversation = new
        }
    }
    
    private func startAcquaintanceFromSettings() {
        let target: Conversation
        
        if let current = activeConversation, current.messages.isEmpty {
            target = current
        } else {
            let new = Conversation()
            modelContext.insert(new)
            try? modelContext.save()
            activeConversation = new
            target = new
        }
        
        switchSection(to: .chat)
        Task { await chatService.startAcquaintance(for: target, modelContext: modelContext) }
    }
    
    private func openConversation(_ conversation: Conversation) {
        activeConversation = conversation
        selectedSection = .chat
    }
    
    @ViewBuilder
    private func chatSectionView(for conversation: Conversation) -> some View {
        ChatView(
            conversation: conversation,
            chatService: chatService,
            achievementService: achievementService,
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
    }
    
    private func fetchConversation(id: UUID) -> Conversation? {
        var descriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate<Conversation> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }
    
    private func evaluateTribunalGateIfNeeded() {
        guard hasCompletedOnboarding else { return }
        guard !hasEvaluatedGate else { return }
        hasEvaluatedGate = true
        
        if isTribunalUnlocked && !isTribunalInProgress {
            isGateShown = true
        }
    }
    
    private func switchSection(to section: AppSection) {
        guard section != selectedSection else { return }
        guard !(isTribunalInProgress && section != .tribunal) else { return }
        
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
    
    private func showDashboardOnNewDay() {
        guard hasCompletedOnboarding else { return }
        let todayKey = Date().dayKey
        guard lastDashboardShownDateString != todayKey else { return }
        lastDashboardShownDateString = todayKey
        selectedSection = .dashboard
    }
}

extension L10n {
    enum Sections {
        static var dashboard: String {
            switch lang {
            case .en: return "Dashboard"
            case .pl: return "Panel"
            }
        }
        
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
        
        static var meditation: String {
            switch lang {
            case .en: return "Meditation"
            case .pl: return "Medytacja"
            }
        }
    }
}

