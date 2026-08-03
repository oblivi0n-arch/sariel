import SwiftUI

struct PendingDeclarationRow: View {
    let commitment: Commitment
    let onSelect: () -> Void

    @State private var isHovering = false

    private var isSelectable: Bool {
        commitment.sourceMessage?.conversation != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(commitment.declarationText)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)

            Text(commitment.createdAt, style: .date)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
        .padding(12)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.border, lineWidth: isHovering && isSelectable ? 1 : 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard isSelectable else { return }
            onSelect()
        }
        .trackHover($isHovering)
    }
}
