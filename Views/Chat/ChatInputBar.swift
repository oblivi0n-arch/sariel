import SwiftUI

struct ChatInputBar: View {
    @Binding var draft: String
    let isLocked: Bool
    let isSendBlocked: Bool
    var isFocused: FocusState<Bool>.Binding
    let isTribunal: Bool
    let isDeclarationLimitReached: Bool
    let onSend: () -> Void

    @State private var isStamping = false
    @State private var ringScale: CGFloat = 1
    @State private var ringOpacity: Double = 0
    @State private var barFlashOpacity: Double = 0

    private var isDeclaration: Bool {
        !isTribunal && Commitment.isDeclaration(draft)
    }

    private var isBlockedByLimit: Bool {
        isDeclaration && isDeclarationLimitReached
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespaces).isEmpty && !isSendBlocked && !isBlockedByLimit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isBlockedByLimit {
                Text(L10n.ChatInput.declarationLimitReached(count: Commitment.maxPendingDeclarations))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.tribunalAccent.opacity(0.75))
                    .padding(.horizontal, 4)
                    .transition(.opacity)
            } else if isDeclaration {
                Text(L10n.ChatInput.noTakeBacks)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.tribunalAccent.opacity(0.75))
                    .padding(.horizontal, 4)
                    .transition(.opacity)
            }
        }
        HStack(alignment: .bottom, spacing: 10) {
            TextField(L10n.ChatInput.messagePlaceholder, text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background((isDeclaration || isTribunal) ? Theme.tribunalAccent.opacity(0.12) : Theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            (isDeclaration || isTribunal) ? Theme.tribunalAccent.opacity(0.45) : (isFocused.wrappedValue ? Theme.borderStrong : Theme.border),
                            lineWidth: (isDeclaration || isTribunal) ? 1 : (isFocused.wrappedValue ? 1 : 0.5)
                        )
                )
                .onSubmit { if canSend { handleSend() } }
                .disabled(isLocked)
                .focused(isFocused)

            Button(action: handleSend) {
                Image(systemName: isDeclaration ? "seal.fill" : "arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canSend ? (isDeclaration ? Color.white : Theme.background) : Theme.textFaint)
                    .frame(width: 32, height: 32)
                    .background(canSend ? (isDeclaration ? Theme.tribunalAccent.opacity(0.85) : Theme.textPrimary) : Theme.fieldBackground)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(isDeclaration && canSend ? Theme.tribunalAccent.opacity(0.5) : Theme.border, lineWidth: 0.5))
                    .scaleEffect(isStamping ? 0.55 : 1.0)
                    .overlay {
                        Circle()
                            .stroke(Theme.tribunalAccent.opacity(ringOpacity), lineWidth: 2)
                            .scaleEffect(ringScale)
                    }
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(16)
        .animation(.easeInOut(duration: 0.15), value: isDeclaration)
    }
    
    private func handleSend() {
        if isDeclaration {
            withAnimation(.easeIn(duration: 0.05)) { isStamping = true }

            ringScale = 1
            ringOpacity = 0.6
            withAnimation(.easeOut(duration: 0.5)) {
                ringScale = 2.4
                ringOpacity = 0
            }

            barFlashOpacity = 0.18
            withAnimation(.easeOut(duration: 0.4)) {
                barFlashOpacity = 0
            }

            Task {
                try? await Task.sleep(nanoseconds: 90_000_000)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.3)) {
                    isStamping = false
                }
            }
        }
        onSend()
    }
}

extension L10n {
    enum ChatInput {
        static func declarationLimitReached(count: Int) -> String {
            switch lang {
            case .en: return "you're carrying \(count) unresolved declarations already. face the Tribunal before adding another."
            case .pl: return "masz już na sobie \(count) nierozstrzygniętych deklaracji. stań przed Trybunałem, zanim dodasz kolejną."
            }
        }

        static var noTakeBacks: String {
            switch lang {
            case .en: return "no take-backs. that's the whole point of declaring."
            case .pl: return "bez wycofywania się. o to właśnie chodzi w deklarowaniu."
            }
        }

        static var messagePlaceholder: String {
            switch lang {
            case .en: return "Write a message..."
            case .pl: return "Napisz wiadomość..."
            }
        }
    }
}
