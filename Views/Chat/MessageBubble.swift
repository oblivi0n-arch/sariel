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
    var isStreaming: Bool = false

    @State private var isHovering = false
    @State private var editedText: String = ""
    @FocusState private var isEditFieldFocused: Bool
    @State private var revealedCount: Int = 0
    @State private var revealTask: Task<Void, Never>? = nil
    @State private var revealProgress: Double = 0
    @State private var streamingFinished: Bool = true

    private let charsPerSecond: Double = 60

    private var isGuide: Bool { message.messageRole == .guide }
    private var isError: Bool { isGuide && message.content.hasPrefix("⚠️") }

    private var errorParts: (description: String, suggestion: String?) {
        let cleaned = message.content.replacingOccurrences(of: "⚠️ ", with: "")
        let lines = cleaned.split(separator: "\n", maxSplits: 1)
        let description = String(lines.first ?? "")
        let suggestion = lines.count > 1 ? String(lines[1]) : nil
        return (description, suggestion)
    }

    private var revealedText: String {
        String(message.content.prefix(revealedCount))
    }

    private var isRevealing: Bool {
        revealedCount < message.content.count
    }

    private var displayContent: AttributedString {
        if message.content.isEmpty {
            return AttributedString("…")
        } else if isRevealing {
            return AttributedString(revealedText)
        } else {
            return formattedContent(message.content)
        }
    }

    var body: some View {
        VStack(alignment: isGuide ? .leading : .trailing, spacing: 4) {
            if !isError {
                Text(isGuide ? "sariel" : "you")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textMuted)
            }

            if isEditing {
                editingBubble
            } else if isError {
                errorBubble
            } else {
                Text(displayContent)
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
        .onAppear {
            if isStreaming {
                streamingFinished = false
                startRevealing()
            } else {
                streamingFinished = true
                revealedCount = message.content.count
            }
        }
        .onChange(of: isStreaming) { _, newValue in
            if newValue {
                streamingFinished = false
                startRevealing()
            } else {
                streamingFinished = true
            }
        }
        .onDisappear {
            revealTask?.cancel()
        }
    }

    private func startRevealing() {
        revealTask?.cancel()
        revealProgress = Double(revealedCount)
        var lastTick = Date()

        revealTask = Task {
            while !Task.isCancelled {
                let now = Date()
                let dt = now.timeIntervalSince(lastTick)
                lastTick = now

                let target = Double(message.content.count)
                let lag = target - revealProgress

                if lag <= 0 {
                    revealProgress = target
                    revealedCount = message.content.count
                    if streamingFinished { break }
                } else {
                    revealProgress = min(target, revealProgress + charsPerSecond * dt)
                    revealedCount = Int(revealProgress)
                }

                try? await Task.sleep(nanoseconds: 16_000_000)
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

            VStack(alignment: .leading, spacing: 4) {
                Text(errorParts.description)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textPrimary)

                if let suggestion = errorParts.suggestion {
                    Text(suggestion).italic()
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }
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
