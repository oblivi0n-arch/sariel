import SwiftUI

struct BackButton: View {
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(Typography.iconButton)
                .foregroundStyle(isHovering ? Theme.textPrimary : Theme.textMuted)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .trackHover($isHovering)
    }
}
