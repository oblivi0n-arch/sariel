import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject private var connectionMonitor: ConnectionMonitor

    @Bindable var conversation: Conversation
    @Binding var isConversationListOpen: Bool
    let isActive: Bool
    let achievementService: AchievementService
    @ObservedObject var chatService: ChatService
    @ObservedObject private var themeManager = ThemeManager.shared

    var onJournalEntryCreated: (JournalEntry) -> Void
    var onDeclarationLimitBlocked: () -> Void
    var onDeclarationEditBlocked: () -> Void
    var onOpenJournalEntry: (JournalEntry) -> Void
    var onBackToTribunal: () -> Void

    @Query(filter: #Predicate<Commitment> { $0.status == "pending" })
    var pendingCommitments: [Commitment]
    
    @AppStorage("hasStartedAcquaintance") private var hasStartedAcquaintance: Bool = false
    @AppStorage("aboutMe") private var aboutMe: String = ""

    @State private var draft: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var editingMessageID: UUID?
    @State private var isMoodPromptShown = false
    @State private var isRevealFinishing = false
    @State private var justDeclared = false
    @State private var pendingDeclarationText: String? = nil
    @State var tribunalVerdicts: [TribunalVerdict] = []
    @State var isVerdictOverlayShown = false
    @Namespace var sealNamespace
    @State var showSeal = false
    @State var sealDocked = false
    @State var hasPlayedSealIntro = false

    init(conversation: Conversation, chatService: ChatService, achievementService: AchievementService, isConversationListOpen: Binding<Bool>, onJournalEntryCreated: @escaping (JournalEntry) -> Void, onDeclarationLimitBlocked: @escaping () -> Void, onDeclarationEditBlocked: @escaping () -> Void, onOpenJournalEntry: @escaping (JournalEntry) -> Void, onBackToTribunal: @escaping () -> Void, isActive: Bool) {
        self.conversation = conversation
        self._isConversationListOpen = isConversationListOpen
        self.chatService = chatService
        self.achievementService = achievementService
        self.onJournalEntryCreated = onJournalEntryCreated
        self.onDeclarationLimitBlocked = onDeclarationLimitBlocked
        self.onDeclarationEditBlocked = onDeclarationEditBlocked
        self.onOpenJournalEntry = onOpenJournalEntry
        self.onBackToTribunal = onBackToTribunal
        self.isActive = isActive
    }

    var sortedMessages: [ChatMessage] {
        conversation.messages.sorted { $0.timestamp < $1.timestamp }
    }

    private var lastUserMessage: ChatMessage? {
        sortedMessages.last(where: { $0.messageRole == .user })
    }

    private var lastGuideMessage: ChatMessage? {
        sortedMessages.last(where: { $0.messageRole == .guide })
    }

    var successfulExchangeCount: Int {
        let sorted = sortedMessages
        return sorted.indices.filter { index in
            let message = sorted[index]
            guard message.messageRole == .guide, message.isValidExchange else { return false }
            guard index > 0 else { return false }
            return sorted[index - 1].messageRole == .user
        }.count
    }

    private var isPendingProvocationStart: Bool {
        conversation.isProvocation && sortedMessages.count == 1 && sortedMessages[0].messageRole == .guide
    }

    private var isPendingAcquaintanceStart: Bool {
        conversation.isAcquaintance && sortedMessages.count == 1 && sortedMessages[0].messageRole == .guide
    }

    private var isEnded: Bool { conversation.journalEntry != nil || conversation.tribunalResolvedAt != nil }

    var isGenerating: Bool { chatService.generatingConversationIDs.contains(conversation.id) }

    private var isEndingConversation: Bool { chatService.endingConversationIDs.contains(conversation.id) }

    private var endConversationError: String? { chatService.endConversationErrors[conversation.id] }
    
    private var isShowingProgressBar: Bool {
        isEndingConversation || chatService.isGeneratingVerdicts.contains(conversation.id)
    }

    var isInputLocked: Bool {
        conversation.isArchived || isGenerating || isEndingConversation || isRevealFinishing || chatService.isGeneratingVerdicts.contains(conversation.id)
    }

    private var hasUnresolvedError: Bool {
        lastGuideMessage?.content.hasPrefix("⚠️") == true
    }

    var isSendBlocked: Bool {
        isInputLocked || hasUnresolvedError
    }

    var isDeclarationLimitReached: Bool {
        pendingCommitments.count >= Commitment.maxPendingDeclarations
    }

    private func wouldExceedDeclarationLimit(_ text: String) -> Bool {
        !conversation.isTribunal && Commitment.isDeclaration(text) && isDeclarationLimitReached
    }
    
    private var pendingAboutMeDraft: String? {
        guard conversation.isAcquaintance else { return nil }
        return chatService.pendingAboutMeDrafts[conversation.id]
    }

    private var isRegeneratingAboutMeDraft: Bool {
        chatService.isGeneratingAboutMeDraft.contains(conversation.id)
    }
    
    private var conversationStartedAt: Date {
        sortedMessages.first?.timestamp ?? conversation.startedAt
    }
    
    private var isDeclaration: Bool {
        !conversation.isTribunal && Commitment.isDeclaration(draft)
    }

    var body: some View {
        contentStack
            .background(Theme.background)
            .onAppear {
                guard connectionMonitor.isConnected else { return }
                triggerAutoRetryIfNeeded()
            }
            .onChange(of: connectionMonitor.isConnected) { oldValue, newValue in
                guard newValue, !oldValue else { return }
                triggerAutoRetryIfNeeded()
            }
            .overlay { moodPromptOverlayContent }
            .overlay { failureMeaningPromptOverlayContent }
            .overlay { aboutMePreviewOverlayContent }
            .overlay { tribunalVerdictOverlayContent }
            .overlay { sealCenterOverlayContent }
            .animation(.easeInOut(duration: 0.2), value: isMoodPromptShown)
            .animation(.easeInOut(duration: 0.2), value: isShowingProgressBar)
            .animation(.easeOut(duration: 0.35), value: isEnded)
    }

    @ViewBuilder
    private var contentStack: some View {
        VStack(spacing: 0) {
            ChatHeaderView(
                title: conversation.title,
                isConversationListOpen: $isConversationListOpen,
                isConnected: connectionMonitor.isConnected,
                isInputLocked: isInputLocked,
                isEnded: isEnded,
                isEndingConversation: isEndingConversation,
                endConversationError: endConversationError,
                canEndConversation: successfulExchangeCount >= 2,
                onOpenSavedEntry: {
                    if let entry = conversation.journalEntry {
                        onOpenJournalEntry(entry)
                    }
                },
                onRequestEndConversation: { isMoodPromptShown = true },
                isTribunal: conversation.isTribunal,
                isGeneratingVerdicts: chatService.isGeneratingVerdicts.contains(conversation.id),
                canDeliverVerdicts: canDeliverVerdicts,
                verdictError: chatService.verdictErrors[conversation.id],
                onDeliverVerdicts: deliverVerdicts,
                onBackToTribunal: onBackToTribunal
            )
            
            if isShowingProgressBar {
                PulsingLoadingBar()
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(sortedMessages) { message in
                            messageRow(for: message, proxy: proxy)
                        }
                    }
                    .padding(20)
                }
                .overlay {
                    if sortedMessages.isEmpty {
                        emptyConversationState
                    }
                }
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [Theme.background, Theme.background.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    .allowsHitTesting(false)
                }
                .onChange(of: conversation.messages.count) {
                    scrollToBottom(proxy)
                }
                .onChange(of: sortedMessages.last?.content) {
                    scrollToBottom(proxy, animated: false)
                }
                .onChange(of: isGenerating) { _, newValue in
                    if !newValue {
                        isRevealFinishing = true
                    } else {
                        isRevealFinishing = false
                    }
                }
                .onChange(of: isActive) { _, newValue in
                    if newValue {
                        DispatchQueue.main.async {
                            isInputFocused = true
                        }
                    }
                }
                .onAppear {
                    scrollToBottom(proxy, animated: false)
                    DispatchQueue.main.async {
                        isInputFocused = true
                    }
                    setupSealIfNeeded()
                }
            }

            if isEnded {
                endedClosing
            } else {
                VStack(spacing: 0) {
                    if sortedMessages.isEmpty && !isDeclaration {
                        HStack(spacing: 8) {
                            StarterChip(icon: "eye", label: L10n.Chat.provocationChip, onTap: startProvocation)

                            if !hasStartedAcquaintance {
                                StarterChip(icon: "person.fill.questionmark", label: L10n.Chat.acquaintanceChip, isHighlighted: true, onTap: startAcquaintance)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .transition(.opacity)
                    }

                    if conversation.isTribunal, showSeal, sealDocked {
                        TribunalSealBanner(isDocked: true)
                            .matchedGeometryEffect(id: "sealBanner", in: sealNamespace)
                    }

                    ChatInputBar(draft: $draft, isLocked: isInputLocked, isSendBlocked: isSendBlocked, isFocused: $isInputFocused, isTribunal: conversation.isTribunal, isDeclarationLimitReached: isDeclarationLimitReached, onSend: sendMessage)
                }
                .animation(.easeInOut(duration: 0.15), value: isDeclaration)
            }
        }
    }

    @ViewBuilder
    private var moodPromptOverlayContent: some View {
        if isMoodPromptShown {
            MoodPromptOverlay(
                onSelect: { mood in
                    isMoodPromptShown = false
                    endConversation(mood: mood)
                },
                onCancel: {
                    isMoodPromptShown = false
                }
            )
        }
    }
    
    @ViewBuilder
    private var failureMeaningPromptOverlayContent: some View {
        if pendingDeclarationText != nil {
            FailureMeaningOverlay(
                onSubmit: submitPendingDeclaration,
                onCancel: cancelPendingDeclaration
            )
        }
    }
    
    @ViewBuilder
    private func messageRow(for message: ChatMessage, proxy: ScrollViewProxy) -> some View {
        let isLastUser = message.id == lastUserMessage?.id
        let isStreamingMessage = isGenerating && message.id == lastGuideMessage?.id
        let isNewlyDeclaredMessage = justDeclared && isLastUser

        let showActions = isLastUser
            && !isInputLocked
            && !isEnded
            && !conversation.isTribunal
            && message.commitment == nil

        let showRewind = message.messageRole == .user
            && !isLastUser
            && !isInputLocked
            && !isEnded
            && !conversation.isTribunal
            && message.commitment == nil
            && !rewindWouldDeleteCommitment(message)

        MessageBubble(
            message: message,
            showActions: showActions,
            onDelete: { deleteLastExchange() },
            isEditing: editingMessageID == message.id,
            onStartEdit: { editingMessageID = message.id },
            onSaveEdit: { newText in saveEdit(for: message, newText: newText) },
            onCancelEdit: { editingMessageID = nil },
            showRewind: showRewind,
            onRewind: { rewind(to: message) },
            onRetry: { retryLastResponse() },
            isStreaming: isStreamingMessage,
            onRevealTick: { scrollToBottom(proxy, animated: false) },
            onRevealComplete: {
                isRevealFinishing = false
                if !isEnded {
                    isInputFocused = true
                }
            },
            isNewlyDeclared: isNewlyDeclaredMessage

        )
        .id(message.id)
    }
    
    @ViewBuilder
    private var aboutMePreviewOverlayContent: some View {
        if let draft = pendingAboutMeDraft {
            AboutMePreviewOverlay(
                draftText: draft,
                existingAboutMe: aboutMe,
                isRegenerating: isRegeneratingAboutMeDraft,
                onAccept: {
                    chatService.acceptAboutMeDraft(for: conversation.id)
                },
                onRetry: {
                    Task { await chatService.retryAboutMeDraft(for: conversation, modelContext: modelContext) }
                },
                onSkip: {
                    chatService.skipAboutMeDraft(for: conversation.id)
                }
            )
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool = true) {
        guard let last = sortedMessages.last else { return }
        if animated {
            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
        } else {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    private var emptyConversationState: some View {
        VStack(spacing: 10) {
            Image(systemName: "circle.dashed")
                .font(.system(size: 26))
                .foregroundStyle(Theme.textFaint)

            Text(L10n.Chat.emptyState)
                .font(Theme.voiceFont)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 260)
    }

    private var spansMultipleDays: Bool {
        guard let end = conversationEndedAt else { return false }
        return conversationStartedAt.dayKey != end.dayKey
    }

    private func formattedTimestamp(_ date: Date) -> String {
        spansMultipleDays
            ? date.formatted(date: .abbreviated, time: .shortened)
            : date.formatted(date: .omitted, time: .shortened)
    }

    private var endedClosing: some View {
        HStack(spacing: 0) {
            summaryStat(label: L10n.Chat.startedLabel, value: formattedTimestamp(conversationStartedAt))
            summaryDivider
            summaryStat(label: L10n.Chat.endedLabel, value: conversationEndedAt.map(formattedTimestamp) ?? "—")
            summaryDivider
            summaryStat(label: L10n.Chat.exchangesLabel, value: "\(successfulExchangeCount)")
            summaryDivider
            summaryStat(label: L10n.Chat.durationLabel, value: conversationDurationText)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.border).frame(height: 0.5)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(Theme.border)
            .frame(width: 0.5, height: 22)
    }

    private func summaryStat(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Typography.label)
                .foregroundStyle(Theme.textSecondary)
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
                .textCase(.uppercase)
                .kerning(0.4)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var conversationEndedAt: Date? {
        conversation.isTribunal ? conversation.tribunalResolvedAt : conversation.journalEntry?.createdAt
    }

    private var conversationDurationText: String {
        guard let end = conversationEndedAt else { return "—" }
        let minutes = max(Int(end.timeIntervalSince(conversationStartedAt) / 60), 0)
        return "\(minutes) min"
    }

    private func sendMessage() {
        guard !isInputLocked else { return }
        guard !wouldExceedDeclarationLimit(draft) else {
            onDeclarationLimitBlocked()
            return
        }
        let text = draft
        let isDeclaringNow = !conversation.isTribunal && Commitment.isDeclaration(text)
        draft = ""

        if isDeclaringNow {
            pendingDeclarationText = text
            return
        }

        Task {
            await chatService.send(text: text, in: conversation, modelContext: modelContext)
        }
    }
    
    private func submitPendingDeclaration(failureMeaning: String) {
        guard let text = pendingDeclarationText else { return }

        pendingDeclarationText = nil
        justDeclared = true

        Task {
            await chatService.send(text: text, failureMeaning: failureMeaning, in: conversation, modelContext: modelContext)
            try? await Task.sleep(nanoseconds: 900_000_000)
            justDeclared = false
        }
    }

    private func cancelPendingDeclaration() {
        if let text = pendingDeclarationText {
            draft = text
        }
        pendingDeclarationText = nil
    }

    private func endConversation(mood: Mood) {
        Task {
            if let entry = await chatService.endConversation(for: conversation, mood: mood, modelContext: modelContext) {
                onJournalEntryCreated(entry)
            }
        }
    }

    private func deleteLastExchange() {
        guard let last = lastUserMessage else { return }
        chatService.deleteMessages(from: last, in: conversation, modelContext: modelContext)
    }

    private func replyMessage(for userMessage: ChatMessage) -> ChatMessage? {
        let sorted = conversation.messages.sorted { $0.timestamp < $1.timestamp }
        guard let idx = sorted.firstIndex(where: { $0.id == userMessage.id }) else { return nil }
        let nextIdx = sorted.index(after: idx)
        guard nextIdx < sorted.count, sorted[nextIdx].messageRole == .guide else { return nil }
        return sorted[nextIdx]
    }

    private func rewind(to message: ChatMessage) {
        guard message.messageRole == .user else { return }
        let cutoffMessage = replyMessage(for: message) ?? message
        chatService.deleteMessages(after: cutoffMessage, in: conversation, modelContext: modelContext)
    }
    
    private func rewindWouldDeleteCommitment(_ message: ChatMessage) -> Bool {
        let cutoffMessage = replyMessage(for: message) ?? message
        return sortedMessages.contains { $0.timestamp > cutoffMessage.timestamp && $0.commitment != nil }
    }
    
    private func saveEdit(for message: ChatMessage, newText: String) {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !wouldExceedDeclarationLimit(trimmed) else {
            editingMessageID = nil
            onDeclarationLimitBlocked()
            return
        }
        guard !(!conversation.isTribunal && Commitment.isDeclaration(trimmed)) else {
            editingMessageID = nil
            onDeclarationEditBlocked()
            return
        }
        editingMessageID = nil
        chatService.deleteMessages(from: message, in: conversation, modelContext: modelContext)
        Task { await chatService.send(text: trimmed, in: conversation, modelContext: modelContext) }
    }
    
    private func retryLastResponse() {
        Task { await chatService.retryLastResponse(for: conversation, modelContext: modelContext) }
    }
    
    private func triggerAutoRetryIfNeeded() {
        guard hasUnresolvedError, !isInputLocked else { return }
        if isPendingProvocationStart {
            Task { await chatService.retryProvocation(for: conversation, modelContext: modelContext) }
        } else if isPendingAcquaintanceStart {
            Task { await chatService.retryAcquaintance(for: conversation, modelContext: modelContext) }
        } else if isPendingTribunalOpening {
            Task { await chatService.retryTribunalOpening(for: conversation, modelContext: modelContext) }
        } else {
            retryLastResponse()
        }
    }
    
    private func startProvocation() {
        guard !isInputLocked else { return }
        Task { await chatService.startProvocation(for: conversation, modelContext: modelContext) }
    }

    private func startAcquaintance() {
        guard !isInputLocked else { return }
        Task { await chatService.startAcquaintance(for: conversation, modelContext: modelContext) }
    }
}

extension L10n {
    enum Chat {
        static var provocationChip: String {
            switch lang {
            case .en: return "provocation"
            case .pl: return "prowokacja"
            }
        }
        
        static var acquaintanceChip: String {
            switch lang {
            case .en: return "get acquainted"
            case .pl: return "zapoznaj się"
            }
        }

        static var emptyState: String {
            switch lang {
            case .en: return "The mirror is empty.\nSay something true."
            case .pl: return "Lustro jest puste.\nPowiedz coś prawdziwego."
            }
        }
        
        static var startedLabel: String {
            switch lang {
            case .en: return "started"
            case .pl: return "start"
            }
        }
        static var endedLabel: String {
            switch lang {
            case .en: return "ended"
            case .pl: return "koniec"
            }
        }
        static var exchangesLabel: String {
            switch lang {
            case .en: return "exchanges"
            case .pl: return "wymian"
            }
        }
        static var durationLabel: String {
            switch lang {
            case .en: return "duration"
            case .pl: return "czas"
            }
        }
    }
}
