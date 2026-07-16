import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var conversation: Conversation
    @Binding var isConversationListOpen: Bool

    @StateObject private var chatService: ChatService
    @State private var draft: String = ""

    init(conversation: Conversation, modelContext: ModelContext, isConversationListOpen: Binding<Bool>) {
        self.conversation = conversation
        self._isConversationListOpen = isConversationListOpen
        _chatService = StateObject(wrappedValue: ChatService(modelContext: modelContext))
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
                
                Button(action: { endConversation() }) {
                    Text("End conversation")
                }
                .disabled(chatService.isEndingConversation == true || chatService.isGenerating || conversation.messages.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(sortedMessages) { message in
                            MessageBubble(message: message)
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
                .onAppear {
                    scrollToBottom(proxy, animated: false)
                }
            }

            inputBar
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

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(draft.isEmpty ? Theme.textFaint : Theme.textPrimary)
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || chatService.isGenerating)
        }
        .padding(16)
    }

    private func sendMessage() {
        let text = draft
        draft = ""
        Task { await chatService.send(text: text, in: conversation) }
    }
    
    private func endConversation() {
        Task { await chatService.endConversation(for: conversation) }
    }
}
