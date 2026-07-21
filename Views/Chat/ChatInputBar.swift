import SwiftUI

struct ChatInputBar: View {
    @Binding var draft: String
    let isLocked: Bool
    var isFocused: FocusState<Bool>.Binding
    let isTribunal: Bool
    let onSend: () -> Void

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespaces).isEmpty && !isLocked
    }
    
    private var isDeclaration: Bool {
        !isTribunal && Commitment.isDeclaration(draft)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isDeclaration {
                Text("no edits. no rewinds. say it if you mean it.")
                    .font(Typography.caption)
                    .foregroundStyle(Color.red.opacity(0.75))
                    .padding(.horizontal, 4)
                    .transition(.opacity)
            }
        }
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Write a message...", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isFocused.wrappedValue ? Theme.borderStrong : Theme.border,
                                lineWidth: isFocused.wrappedValue ? 1 : 0.5)
                )
                .onSubmit(onSend)
                .disabled(isLocked)
                .focused(isFocused)

            Button(action: onSend) {
                Image(systemName: isDeclaration ? "seal.fill" : "arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canSend ? (isDeclaration ? Color.white : Theme.background) : Theme.textFaint)
                    .frame(width: 32, height: 32)
                    .background(canSend ? (isDeclaration ? Color.red.opacity(0.85) : Theme.textPrimary) : Theme.fieldBackground)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(isDeclaration && canSend ? Color.red.opacity(0.5) : Theme.border, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(16)
        .animation(.easeInOut(duration: 0.15), value: isDeclaration)
    }
}
