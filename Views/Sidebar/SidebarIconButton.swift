import SwiftUI

struct SidebarIconButton: View {
    let iconName: String
    let isActive: Bool
    var isLocked: Bool = false
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 18))
            .foregroundStyle(foregroundColor)
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
            .overlay(alignment: .bottomTrailing) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(Theme.textFaint)
                        .padding(3)
                        .background(Theme.background)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
            }
            .opacity(isLocked ? 0.35 : 1)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isLocked else { return }
                onTap()
            }
            .onHover { hovering in
                guard !isLocked else { return }
                isHovering = hovering
            }
            .help(isLocked ? "End Tribunal session first" : "")
    }

    private var foregroundColor: Color {
        if isActive { return Theme.textPrimary }
        if isHovering { return Theme.textMuted }
        return Theme.textFaint
    }

    private var borderColor: Color {
        if isActive { return Theme.borderStrong }
        if isHovering { return Theme.border }
        return .clear
    }
}
