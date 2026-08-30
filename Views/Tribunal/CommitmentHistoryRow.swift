import SwiftUI

struct CommitmentHistoryRow: View {
    let commitment: Commitment
    let onSelect: () -> Void

    @State private var isHovering = false

    private var isFulfilled: Bool {
        commitment.commitmentStatus == .fulfilled
    }

    private var isSelectable: Bool {
        commitment.resolvingConversation != nil
    }

    private var borderColor: Color {
        isFulfilled ? Theme.textPrimary : Theme.tribunalAccent.opacity(0.6)
    }
    
    private var statusBadge: some View {
        Text(isFulfilled ? L10n.CommitmentHistory.fulfilled : L10n.CommitmentHistory.broken)
            .font(Typography.caption)
            .foregroundStyle(isFulfilled ? Theme.textMuted : Theme.tribunalAccent.opacity(0.8))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(commitment.declarationText)
                    .font(Theme.uiFont)
                    .foregroundStyle(isFulfilled ? Theme.textPrimary : Theme.textSecondary)
                    .lineLimit(2)

                Spacer()

                statusBadge
            }

            if let reasoning = commitment.verdictReasoning, !reasoning.isEmpty {
                Text(reasoning)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
                    .lineLimit(2)
            }

            if let resolvedAt = commitment.resolvedAt {
                Text(resolvedAt.formatted(
                    .dateTime.day().month().year()
                    .locale(LanguageManager.shared.locale)
                ))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
            }
        }
        .padding(12)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: isHovering && isSelectable ? 1 : 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard isSelectable else { return }
            onSelect()
        }
        .trackHover($isHovering)
    }
}

extension L10n {
    enum CommitmentHistory {
        static var fulfilled: String {
            switch lang {
            case .en: return "Fulfilled"
            case .pl: return "Dotrzymano"
            }
        }
        static var broken: String {
            switch lang {
            case .en: return "Broken"
            case .pl: return "Złamano"
            }
        }
    }
}
