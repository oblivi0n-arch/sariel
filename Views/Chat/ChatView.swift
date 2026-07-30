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
                    if sortedMessages.isEmpty {
                        HStack(spacing: 8) {
                            StarterChip(icon: "eye", label: L10n.Chat.provocationChip, onTap: startProvocation)

                            if !hasStartedAcquaintance {
                                StarterChip(icon: "person.fill.questionmark", label: L10n.Chat.acquaintanceChip, onTap: startAcquaintance)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    if conversation.isTribunal, showSeal, sealDocked {
                        TribunalSealBanner(isDocked: true)
                            .matchedGeometryEffect(id: "sealBanner", in: sealNamespace)
                    }

                    ChatInputBar(draft: $draft, isLocked: isInputLocked, isSendBlocked: isSendBlocked, isFocused: $isInputFocused, isTribunal: conversation.isTribunal, isDeclarationLimitReached: isDeclarationLimitReached, onSend: sendMessage)
                }
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

    private var endedClosing: some View {
        HStack {
            Spacer()
            Text(conversation.isTribunal ? L10n.Chat.verdictsDelivered : L10n.Chat.reflectionRecorded)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
            Spacer()
        }
        .padding(.vertical, 18)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.border).frame(height: 0.5)
        }
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

        static var verdictsDelivered: String {
            switch lang {
            case .en: return "— verdicts delivered —"
            case .pl: return "— wyroki wydane —"
            }
        }

        static var reflectionRecorded: String {
            switch lang {
            case .en: return "— reflection recorded —"
            case .pl: return "— refleksja zapisana —"
            }
        }
    }
}
