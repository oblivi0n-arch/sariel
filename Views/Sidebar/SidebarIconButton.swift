import SwiftUI

struct SidebarIconButton: View {
    let iconName: String
    let isActive: Bool
    var isLocked: Bool = false
    var showAlertBadge: Bool = false
    let onTap: () -> Void
    
    @State private var isHovering = false
    @State private var isPulsing = false
    
    private var effectivelyLocked: Bool {
        isLocked && !isActive
    }
    
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
                if effectivelyLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(Theme.textFaint)
                        .padding(3)
                        .background(Theme.background)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
            }
            .opacity(effectivelyLocked ? 0.35 : 1)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !effectivelyLocked else { return }
                onTap()
            }
            .onHover { hovering in
                guard !effectivelyLocked else { return }
                isHovering = hovering
            }
            .help(effectivelyLocked ? "End Tribunal session first" : "")
            .focusEffectDisabled()
            .onAppear { startPulsingIfNeeded() }
            .onChange(of: showAlertBadge) { _, _ in startPulsingIfNeeded() }
    }
    
    private func startPulsingIfNeeded() {
        guard showAlertBadge, !effectivelyLocked else {
            isPulsing = false
            return
        }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
    
    private var foregroundColor: Color {
        if effectivelyLocked { return Theme.textFaint }
        if showAlertBadge {
            return isPulsing ? Color.red.opacity(0.9) : Theme.textFaint
        }
        if isActive { return Theme.textPrimary }
        if isHovering { return Theme.textMuted }
        return Theme.textFaint
    }
    
    private var borderColor: Color {
        if effectivelyLocked { return .clear }
        if showAlertBadge {
            return isPulsing ? Color.red.opacity(0.5) : Theme.border
        }
        if isActive { return Theme.borderStrong }
        if isHovering { return Theme.border }
        return .clear
    }
}
