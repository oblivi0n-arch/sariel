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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(commitment.declarationText)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textSecondary)
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
                Text(resolvedAt, style: .date)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
            }
        }
        .padding(12)
        .background(Theme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovering && isSelectable ? Theme.borderStrong : (isFulfilled ? Theme.border : Color.red.opacity(0.4)), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard isSelectable else { return }
            onSelect()
        }
        .onHover { hovering in isHovering = hovering }
    }

    private var statusBadge: some View {
        Text(isFulfilled ? "Fulfilled" : "Broken")
            .font(Typography.caption)
            .foregroundStyle(isFulfilled ? Theme.textMuted : Color.red.opacity(0.8))
    }
}
