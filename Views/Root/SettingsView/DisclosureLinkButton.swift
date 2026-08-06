import SwiftUI

struct DisclosureLinkButton: View {
    let title: String
    @Binding var isExpanded: Bool

    @State private var isHovering = false

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .medium))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .font(Typography.caption)
            .foregroundStyle(isHovering ? Theme.textPrimary : Theme.textMuted)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .trackHover($isHovering)
    }
}
