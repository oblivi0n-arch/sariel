import SwiftUI

struct ChatInputBar: View {
    @Binding var draft: String
    let isLocked: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespaces).isEmpty && !isLocked
    }

    var body: some View {
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
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canSend ? Theme.background : Theme.textFaint)
                    .frame(width: 32, height: 32)
                    .background(canSend ? Theme.textPrimary : Theme.fieldBackground)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.border, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(16)
    }
}
