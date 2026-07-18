import SwiftUI

struct SidebarIconButton: View {
    let iconName: String
    let isActive: Bool
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
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .onHover { hovering in isHovering = hovering }
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
