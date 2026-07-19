import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var conversation: Conversation
    @Binding var isConversationListOpen: Bool
    let isActive: Bool

    @ObservedObject private var chatService: ChatService
    @State private var draft: String = ""
    @EnvironmentObject private var connectionMonitor: ConnectionMonitor
    @FocusState private var isInputFocused: Bool
    @State private var editingMessageID: UUID?
    @State private var isMoodPromptShown = false
    private var isEnded: Bool { conversation.journalEntry != nil }
    private var successfulExchangeCount: Int {
        conversation.messages.filter { $0.messageRole == .guide && !$0.content.hasPrefix("⚠️") }.count
    }
    private var isGenerating: Bool { chatService.generatingConversationIDs.contains(conversation.id) }
    private var isEndingConversation: Bool { chatService.endingConversationIDs.contains(conversation.id) }
    private var isInputLocked: Bool { isGenerating || isEndingConversation }
    private var endConversationError: String? { chatService.endConversationErrors[conversation.id] }
    private var lastStreamError: String? { chatService.lastErrors[conversation.id] }
    private var lastUserMessage: ChatMessage? {
        sortedMessages.last(where: { $0.messageRole == .user })
    }
    private var lastGuideMessage: ChatMessage? {
        sortedMessages.last(where: { $0.messageRole == .guide })
    }
    
    var onJournalEntryCreated: (JournalEntry) -> Void
    var onOpenJournalEntry: (JournalEntry) -> Void
    
    private var isPendingProvocationStart: Bool {
        sortedMessages.count == 1 && sortedMessages[0].messageRole == .guide
    }

    init(conversation: Conversation, chatService: ChatService, isConversationListOpen: Binding<Bool>, onJournalEntryCreated: @escaping (JournalEntry) -> Void, onOpenJournalEntry: @escaping (JournalEntry) -> Void, isActive: Bool) {
        self.conversation = conversation
        self._isConversationListOpen = isConversationListOpen
        self.chatService = chatService
        self.onJournalEntryCreated = onJournalEntryCreated
        self.onOpenJournalEntry = onOpenJournalEntry
        self.isActive = isActive
    }

    private var sortedMessages: [ChatMessage] {
        conversation.messages.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            ChatHeaderView(
                title: conversation.title,
                isConversationListOpen: $isConversationListOpen,
                isEnded: isEnded,
                isEndingConversation: isEndingConversation,
                endConversationError: endConversationError,
                canEndConversation: successfulExchangeCount >= 2,
                isGenerating: isGenerating,
                isConnected: connectionMonitor.isConnected,
                onOpenSavedEntry: {
                    if let entry = conversation.journalEntry {
                        onOpenJournalEntry(entry)
                    }
                },
                onRequestEndConversation: { isMoodPromptShown = true }
            )

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(sortedMessages) { message in
                            let isLastUser = message.id == lastUserMessage?.id
                            MessageBubble(
                                message: message,
                                showActions: isLastUser && !isGenerating && !isEndingConversation && !isEnded,
                                onDelete: { deleteLastExchange() },
                                isEditing: editingMessageID == message.id,
                                onStartEdit: { editingMessageID = message.id },
                                onSaveEdit: { newText in saveEdit(for: message, newText: newText) },
                                onCancelEdit: { editingMessageID = nil },
                                showRewind: message.messageRole == .user && !isLastUser && !isGenerating && !isEndingConversation && !isEnded,
                                onRewind: { rewind(to: message) },
                                onRetry: { retryLastResponse() }
                            )
                            .id(message.id)
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
                        isInputFocused = true
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
                }
            }

            if isEnded {
                endedClosing
            } else {
                VStack(spacing: 0) {
                    if sortedMessages.isEmpty {
                        HStack(spacing: 8) {
                            StarterChip(icon: "eye", label: "provocation", onTap: startProvocation)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    ChatInputBar(draft: $draft, isLocked: isInputLocked, isFocused: $isInputFocused, onSend: sendMessage)
                }
            }
        }
        .background(Theme.background)
        .onChange(of: connectionMonitor.isConnected) { oldValue, newValue in
            guard newValue, !oldValue else { return }
            guard lastStreamError != nil, !isInputLocked else { return }
            if isPendingProvocationStart {
                Task { await chatService.retryProvocation(for: conversation, modelContext: modelContext) }
            } else {
                retryLastResponse()
            }
        }
        .overlay {
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
        .animation(.easeInOut(duration: 0.2), value: isMoodPromptShown)
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

            Text("The mirror is empty.\nSay something true.")
                .font(Theme.voiceFont)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 260)
    }

    private var endedClosing: some View {
        HStack {
            Spacer()
            Text("— reflection recorded —")
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
        let text = draft
        draft = ""
        Task { await chatService.send(text: text, in: conversation, modelContext: modelContext) }
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
    
    private func saveEdit(for message: ChatMessage, newText: String) {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        editingMessageID = nil
        chatService.deleteMessages(from: message, in: conversation, modelContext: modelContext)
        Task { await chatService.send(text: trimmed, in: conversation, modelContext: modelContext) }
    }
    
    private func retryLastResponse() {
        Task { await chatService.retryLastResponse(for: conversation, modelContext: modelContext) }
    }
    
    private func startProvocation() {
        guard !isInputLocked else { return }
        Task { await chatService.startProvocation(for: conversation, modelContext: modelContext) }
    }
}
