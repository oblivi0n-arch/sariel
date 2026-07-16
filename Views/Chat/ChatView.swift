import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var conversation: Conversation
    @Binding var isConversationListOpen: Bool

    @ObservedObject private var chatService: ChatService
    @State private var draft: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var isHoveringEndButton = false
    private var isEnded: Bool { conversation.journalEntry != nil }
    private var successfulExchangeCount: Int {
        conversation.messages.filter { $0.messageRole == .guide && !$0.content.hasPrefix("⚠️") }.count
    }
    private var isGenerating: Bool { chatService.generatingConversationIDs.contains(conversation.id) }
    private var isEndingConversation: Bool { chatService.endingConversationIDs.contains(conversation.id) }
    private var isInputLocked: Bool { isGenerating || isEndingConversation }
    private var endConversationError: String? { chatService.endConversationErrors[conversation.id] }
    private var lastUserMessage: ChatMessage? {
        sortedMessages.last(where: { $0.messageRole == .user })
    }
    var onJournalEntryCreated: (JournalEntry) -> Void

    init(conversation: Conversation, chatService: ChatService, isConversationListOpen: Binding<Bool>, onJournalEntryCreated: @escaping (JournalEntry) -> Void) {
        self.conversation = conversation
        self._isConversationListOpen = isConversationListOpen
        self.chatService = chatService
        self.onJournalEntryCreated = onJournalEntryCreated
    }

    private var sortedMessages: [ChatMessage] {
        conversation.messages.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { isConversationListOpen.toggle() }) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
                .opacity(isConversationListOpen ? 0 : 1)
                .disabled(isConversationListOpen)

                Spacer()
                if isEnded {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(Typography.caption)
                        Text("saved to journal")
                            .font(Typography.caption)
                    }
                    .foregroundStyle(Theme.textMuted)
                } else if isEndingConversation {
                    EndConversationLoadingBar()
                        .frame(width: 100)
                } else if let error = endConversationError {
                    Button(action: { endConversation() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(Typography.label)
                            Text("something went wrong – tap to retry")
                                .font(Typography.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textPrimary)
                    .help(error)
                } else {
                    Button(action: {
                        guard !isGenerating && successfulExchangeCount >= 2 else { return }
                        endConversation()
                    }) {
                            Text("end conversation")
                        
                    }
                    .padding(10)
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
                    .contentShape(Rectangle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isHoveringEndButton ? Theme.border : .clear, lineWidth: 0.5)
                    )
                    .onHover { hovering in isHoveringEndButton = hovering }
                    .opacity(successfulExchangeCount < 2 ? 0.4 : 1)
                    .help(successfulExchangeCount < 2 ? "conversation is too short to save" : "")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(sortedMessages) { message in
                            let isLastUser = message.id == lastUserMessage?.id
                            MessageBubble(
                                message: message,
                                showActions: message.id == lastUserMessage?.id && !isGenerating && !isEndingConversation,
                                onDelete: { deleteLastExchange() },
                                showRewind: message.messageRole == .user && !isLastUser && !isGenerating && !isEndingConversation,
                                onRewind: { rewind(to: message) }
                            )
                            .id(message.id)
                        }
                    }
                    .padding(20)
                }
                .onChange(of: conversation.messages.count) {
                    scrollToBottom(proxy)
                }
                .onChange(of: sortedMessages.last?.content) {
                    scrollToBottom(proxy)
                }
                .onChange(of: isGenerating) { _, newValue in
                    if !newValue {
                        isInputFocused = true
                    }
                }
                .onAppear {
                    scrollToBottom(proxy, animated: false)
                    isInputFocused = true
                }
            }
            
            if isEnded {
                endedFooter
            } else {
                inputBar
            }
        }
        .background(Theme.background)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool = true) {
        guard let last = sortedMessages.last else { return }
        if animated {
            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
        } else {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("write a message...", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                .onSubmit(sendMessage)
                .disabled(isInputLocked)
                .focused($isInputFocused)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(draft.isEmpty ? Theme.textFaint : Theme.textPrimary)
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || isInputLocked)
        }
        .padding(16)
    }
    
    private var endedFooter: some View {
        Button(action: {
            if let entry = conversation.journalEntry {
                onJournalEntryCreated(entry)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.circle.fill")
                    .font(.system(size: 14))
                Text("This conversation is saved – tap to view")
                    .font(Theme.uiFont)
            }
            .foregroundStyle(Theme.textFaint)
            .frame(maxWidth: .infinity)
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    private func sendMessage() {
        guard !isInputLocked else { return }
        let text = draft
        draft = ""
        Task { await chatService.send(text: text, in: conversation, modelContext: modelContext) }
    }
    
    private func endConversation() {
        Task {
            if let entry = await chatService.endConversation(for: conversation, modelContext: modelContext) {
                onJournalEntryCreated(entry)
            }
        }
    }
    
    private func deleteLastExchange() {
        guard let last = lastUserMessage else { return }
        chatService.deleteMessages(from: last, in: conversation, modelContext: modelContext)
    }
    
    private func rewind(to message: ChatMessage) {
        guard message.messageRole == .user else { return }
        let text = message.content
        chatService.deleteMessages(from: message, in: conversation, modelContext: modelContext)
        draft = text
        isInputFocused = true
    }

}
