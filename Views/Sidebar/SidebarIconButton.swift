import SwiftUI

struct SidebarIconButton: View {
    let iconName: String
    let isActive: Bool
    var isLocked: Bool = false
    var showAlertBadge: Bool = false
    var isSolidRed: Bool = false
    let onTap: () -> Void

    @State private var isHovering = false

    private var effectivelyLocked: Bool {
        isLocked && !isActive
    }

    private var isPulseActive: Bool {
        showAlertBadge && !effectivelyLocked && !isSolidRed
    }

    var body: some View {
        Group {
            if isSolidRed && !effectivelyLocked {
                redIcon()
            } else if isPulseActive {
                TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { context in
                    pulsingIcon(intensity: pulseIntensity(at: context.date))
                }
            } else {
                pulsingIcon(intensity: 0)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !effectivelyLocked else { return }
            onTap()
        }
        .onHover { hovering in
            guard !effectivelyLocked else { return }
            isHovering = hovering
        }
        .help(effectivelyLocked ? L10n.Sidebar.lockedTooltip : "")
        .focusEffectDisabled()
    }
    private func baseIcon() -> some View {
        iconShape(foreground: baseForegroundColor, border: baseBorderColor)
    }

    private func redIcon() -> some View {
        iconShape(foreground: Color.red.opacity(0.9), border: Color.red.opacity(0.5))
    }

    private func pulsingIcon(intensity: Double) -> some View {
        baseIcon()
            .overlay(redIcon().opacity(intensity))
    }

    private func iconShape(foreground: Color, border: Color) -> some View {
        Image(systemName: iconName)
            .font(.system(size: 18))
            .foregroundStyle(foreground)
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(border, lineWidth: 1)
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
    }

    private func pulseIntensity(at date: Date) -> Double {
        let period = 1.8
        let t = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
        return t < 0.5 ? t * 2 : (1 - t) * 2
    }

    private var baseForegroundColor: Color {
        if effectivelyLocked { return Theme.textFaint }
        if isActive { return Theme.textPrimary }
        if isHovering { return Theme.textMuted }
        return Theme.textFaint
    }

    private var baseBorderColor: Color {
        if effectivelyLocked { return .clear }
        if isActive { return Theme.borderStrong }
        if isHovering { return Theme.border }
        return .clear
    }
}

extension L10n {
    enum Sidebar {
        static var lockedTooltip: String {
            switch lang {
            case .en: return "End Tribunal session first"
            case .pl: return "Najpierw zakończ sesję Trybunału"
            }
        }
    }
}
