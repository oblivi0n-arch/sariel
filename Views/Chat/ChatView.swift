import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var conversation: Conversation

    @StateObject private var chatService: ChatService
    @State private var draft: String = ""

    init(conversation: Conversation, modelContext: ModelContext) {
        self.conversation = conversation
        _chatService = StateObject(wrappedValue: ChatService(modelContext: modelContext))
    }

    private var sortedMessages: [ChatMessage] {
        conversation.messages.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
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
        
        .toolbar {
            Button(action: clearConversation) {
                Label("Clear Messages", systemImage: "trash")
                    .foregroundColor(.gray)
            }
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

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("write a message...", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                .onSubmit(sendMessage)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(draft.isEmpty ? Theme.textFaint : Theme.accentBright)
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
    
    private func clearConversation() {
        for message in conversation.messages {
            modelContext.delete(message)
        }
        conversation.messages.removeAll()
        try? modelContext.save()
    }
}
