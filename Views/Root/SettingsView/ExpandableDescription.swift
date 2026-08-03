import SwiftUI

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
            .trackHover($isHovering)

            if isExpanded {
                Text(detail)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
                    .transition(.opacity)
            }
        }
    }
}
