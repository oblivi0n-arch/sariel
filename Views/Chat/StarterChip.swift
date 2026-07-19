import SwiftUI

struct StarterChip: View {
    let icon: String
    let label: String
    let onTap: () -> Void

    @State private var isHovering = false

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
        .contentShape(Capsule())
        .onTapGesture(perform: onTap)
        .onHover { hovering in isHovering = hovering }
    }
}
