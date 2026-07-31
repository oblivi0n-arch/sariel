import SwiftUI

struct StarterChip: View {
    let icon: String
    let label: String
    var isHighlighted: Bool = false
    let onTap: () -> Void

    @State private var isHovering = false
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(label)
                .font(Typography.caption)
        }
        .foregroundStyle(isHovering ? Theme.textPrimary : Theme.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.fieldBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(isHovering ? Theme.borderStrong : Theme.border, lineWidth: 0.5))
        .overlay(
            Capsule().stroke(Theme.textPrimary.opacity(isHighlighted ? (isPulsing ? 0.45 : 0.1) : 0), lineWidth: isHighlighted ? 1 : 0)
        )
        .shadow(color: Theme.textPrimary.opacity(isHighlighted ? (isPulsing ? 0.2 : 0) : 0), radius: 5)
        .contentShape(Capsule())
        .onTapGesture(perform: onTap)
        .onHover { hovering in isHovering = hovering }
        .onAppear {
            guard isHighlighted else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
