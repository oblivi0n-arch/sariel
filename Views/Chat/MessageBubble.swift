import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    var showActions: Bool = false
    var onDelete: (() -> Void)? = nil
    var isEditing: Bool = false
    var onStartEdit: (() -> Void)? = nil
    var onSaveEdit: ((String) -> Void)? = nil
    var onCancelEdit: (() -> Void)? = nil
    var showRewind: Bool = false
    var onRewind: (() -> Void)? = nil
    var onRetry: (() -> Void)? = nil

    @State private var isHovering = false
    @State private var editedText: String = ""
    @FocusState private var isEditFieldFocused: Bool

    private var isGuide: Bool { message.messageRole == .guide }
    private var isError: Bool { isGuide && message.content.hasPrefix("⚠️") }

    var body: some View {
        VStack(alignment: isGuide ? .leading : .trailing, spacing: 4) {
            Text(isError ? "error" : (isGuide ? "sariel" : "you"))
                .font(Typography.caption)
                .foregroundStyle(isError ? Theme.textPrimary : Theme.textMuted)

            if isEditing {
                editingBubble
            } else if isError {
                errorBubble
            } else {
                Text(message.content.isEmpty ? AttributedString("…") : formattedContent(message.content))
                    .font(isGuide ? Theme.voiceFont : Theme.uiFont)
                    .foregroundStyle(isGuide ? Theme.textPrimary : Theme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .clipShape(bubbleShape)
                    .overlay(bubbleShape.stroke(Theme.border, lineWidth: 0.5))
                    .overlay(alignment: .leading) {
                        if isGuide {
                            Rectangle().fill(Theme.borderStrong).frame(width: 2)
                        }
                    }
            }
        }
        .frame(maxWidth: 420, alignment: isGuide ? .leading : .trailing)
        .frame(maxWidth: .infinity, alignment: isGuide ? .leading : .trailing)
        .padding(.bottom, 22)
        .overlay(alignment: isGuide ? .bottomLeading : .bottomTrailing) {
            if !isEditing, isHovering {
                if showActions {
                    HStack(spacing: 10) {
                        Button(action: { onStartEdit?() }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .buttonStyle(.plain)
                        
                        if let onRetry {
                            Button(action: onRetry) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if let onDelete {
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                } else if showRewind, let onRewind {
                    Button(action: onRewind) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in isHovering = hovering }
        .onChange(of: isEditing) { _, editing in
            if editing {
                editedText = message.content
                DispatchQueue.main.async {
                    isEditFieldFocused = true
                }
            }
        }
    }

    private var editingBubble: some View {
        VStack(alignment: .trailing, spacing: 6) {
            TextField("", text: $editedText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.fieldBackground)
                .clipShape(bubbleShape)
                .overlay(bubbleShape.stroke(Theme.borderStrong, lineWidth: 0.5))
                .focused($isEditFieldFocused)
                .onSubmit { onSaveEdit?(editedText) }

            HStack(spacing: 12) {
                Button("cancel") { onCancelEdit?() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textMuted)
                Button("save") { onSaveEdit?(editedText) }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textPrimary)
            }
            .font(Typography.caption)
        }
    }

    private var errorBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Typography.label)
                .foregroundStyle(Theme.textPrimary)

            Text(message.content.replacingOccurrences(of: "⚠️ ", with: ""))
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.borderStrong, lineWidth: 1))
    }

    private var bubbleShape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: isGuide ? 0 : 10,
            bottomLeadingRadius: 10,
            bottomTrailingRadius: 10,
            topTrailingRadius: isGuide ? 10 : 0
        )
    }
    
    private func formattedContent(_ text: String) -> AttributedString {
        (try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }
}
