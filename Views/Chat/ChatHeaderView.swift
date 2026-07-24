import SwiftUI

struct ChatHeaderView: View {
    let title: String
    @Binding var isConversationListOpen: Bool
    let isEnded: Bool
    let isEndingConversation: Bool
    let endConversationError: String?
    let canEndConversation: Bool
    let isInputLocked: Bool
    let isConnected: Bool
    let onOpenSavedEntry: () -> Void
    let onRequestEndConversation: () -> Void
    let isTribunal: Bool
    let isGeneratingVerdicts: Bool
    let canDeliverVerdicts: Bool
    let onDeliverVerdicts: () -> Void
    let verdictError: String?
    let onBackToTribunal: () -> Void

    @State private var isHoveringSavedPill = false

    var body: some View {
        ZStack {
            Text(title)
                .font(Typography.label)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: 220)

            HStack {
                if isTribunal {
                    Color.clear.frame(width: 16, height: 16)
                } else {
                    Button(action: { isConversationListOpen.toggle() }) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .buttonStyle(.plain)
                    .opacity(isConversationListOpen ? 0 : 1)
                    .disabled(isConversationListOpen)
                }

                Spacer()

                trailingContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.border).frame(height: 0.5)
        }
    }
    
    @ViewBuilder
    private var trailingContent: some View {
        if isEnded && isTribunal {
            Button(action: onBackToTribunal) {
                statusPill(icon: "arrow.uturn.backward", text: L10n.ChatHeader.backToTribunal)
            }
            .buttonStyle(.plain)
        } else if isEnded {
            Button(action: onOpenSavedEntry) {
                statusPill(
                    icon: "checkmark.circle",
                    text: L10n.ChatHeader.savedTapToView,
                    color: isHoveringSavedPill ? Theme.textPrimary : Theme.textSecondary
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in isHoveringSavedPill = hovering }
        } else if !isConnected {
            statusPill(icon: "wifi.slash", text: L10n.ChatHeader.offline, color: Theme.textMuted)
        } else if isTribunal {
            if let verdictError {
                Button(action: {
                    guard !isInputLocked else { return }
                    onDeliverVerdicts()
                }) {
                    statusPill(icon: "exclamationmark.triangle.fill", text: L10n.ChatHeader.tapToRetry, color: Theme.textPrimary)
                }
                .buttonStyle(.plain)
                .help(verdictError)
            } else {
                Button(action: onDeliverVerdicts) {
                    statusPill(
                        icon: "scalemass",
                        text: isGeneratingVerdicts ? L10n.ChatHeader.judging : L10n.ChatHeader.deliverVerdicts
                    )
                }
                .buttonStyle(.plain)
                .disabled(isGeneratingVerdicts || isInputLocked || !canDeliverVerdicts)
                .opacity(canDeliverVerdicts ? 1 : 0.4)
                .help(canDeliverVerdicts ? "" : L10n.ChatHeader.keepGoingDeclarations)
            }
        } else if let error = endConversationError {
            Button(action: {
                guard !isInputLocked else { return }
                onRequestEndConversation()
            }) {
                statusPill(icon: "exclamationmark.triangle.fill", text: L10n.ChatHeader.tapToRetry, color: Theme.textPrimary)
            }
            .buttonStyle(.plain)
            .help(error)
        } else if isEndingConversation {
            EndConversationLoadingBar()
                .frame(width: 120)
                .clipShape(Capsule())
        } else {
            Button(action: {
                guard !isInputLocked && canEndConversation else { return }
                onRequestEndConversation()
            }) {
                statusPill(icon: "book.closed", text: L10n.ChatHeader.endConversation)
            }
            .buttonStyle(.plain)
            .opacity(!isInputLocked && canEndConversation ? 1 : 0.4)
            .help(canEndConversation ? "" : L10n.ChatHeader.keepGoingNothingToMirror)
        }
    }

    private func statusPill(icon: String, text: String, color: Color = Theme.textSecondary) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            Text(text)
                .font(Typography.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.fieldBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
    }
}

extension L10n {
    enum ChatHeader {
        static var backToTribunal: String {
            switch lang {
            case .en: return "Back to Tribunal"
            case .pl: return "Powrót do Trybunału"
            }
        }

        static var savedTapToView: String {
            switch lang {
            case .en: return "Saved — tap to view"
            case .pl: return "Zapisano — dotknij, by zobaczyć"
            }
        }

        static var offline: String {
            switch lang {
            case .en: return "Offline"
            case .pl: return "Offline"
            }
        }

        static var tapToRetry: String {
            switch lang {
            case .en: return "Tap to retry"
            case .pl: return "Dotknij, by spróbować ponownie"
            }
        }

        static var judging: String {
            switch lang {
            case .en: return "judging..."
            case .pl: return "osądzanie..."
            }
        }

        static var deliverVerdicts: String {
            switch lang {
            case .en: return "deliver verdicts"
            case .pl: return "wydaj wyroki"
            }
        }

        static var keepGoingDeclarations: String {
            switch lang {
            case .en: return "keep going – each declaration deserves its own accounting."
            case .pl: return "mów dalej – każda deklaracja zasługuje na własne rozliczenie."
            }
        }

        static var endConversation: String {
            switch lang {
            case .en: return "End conversation"
            case .pl: return "Zakończ rozmowę"
            }
        }

        static var keepGoingNothingToMirror: String {
            switch lang {
            case .en: return "keep going – nothing to mirror yet."
            case .pl: return "mów dalej – jeszcze nie ma czego odzwierciedlić."
            }
        }
    }
}
