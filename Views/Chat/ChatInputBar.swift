import SwiftUI

struct ChatInputBar: View {
    @Binding var draft: String
    let isLocked: Bool
    var isFocused: FocusState<Bool>.Binding
    let isTribunal: Bool
    let isDeclarationLimitReached: Bool
    let onSend: () -> Void

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespaces).isEmpty && !isLocked && !isBlockedByLimit
    }

    private var isDeclaration: Bool {
        !isTribunal && Commitment.isDeclaration(draft)
    }

    private var isBlockedByLimit: Bool {
        isDeclaration && isDeclarationLimitReached
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
                    if isBlockedByLimit {
                        Text("you're carrying \(Commitment.maxPendingDeclarations) unresolved declarations already. face the Tribunal before adding another.")
                            .font(Typography.caption)
                            .foregroundStyle(Color.red.opacity(0.75))
                            .padding(.horizontal, 4)
                            .transition(.opacity)
                    } else if isDeclaration {
                        Text("no take-backs. that's the whole point of declaring.")
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
                .onSubmit { if canSend { onSend() } }
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
