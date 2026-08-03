import SwiftUI
import AppKit

struct ExpandableDescription: View {
    let short: String
    let detail: String

    @State private var isExpanded = false
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Text(short)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .medium))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .font(Typography.caption)
                .foregroundStyle(isHovering ? Theme.textMuted : Theme.textFaint)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            if isExpanded {
                Text(detail)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
                    .transition(.opacity)
            }
        }
    }
}
