import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var connectionMonitor: ConnectionMonitor
    @Binding var selectedSection: AppSection
    @Binding var isSettingsOpen: Bool
    let isTribunalLocked: Bool
    let isTribunalAwaitingJudgment: Bool

    var body: some View {
        VStack(spacing: 16) {
            statusDot

            ForEach(AppSection.allCases) { section in
                SidebarIconButton(
                    iconName: section.iconName,
                    isActive: section == selectedSection,
                    isLocked: isTribunalLocked && section != .tribunal,
                    showAlertBadge: section == .tribunal && isTribunalAwaitingJudgment,
                    isSolidRed: section == .tribunal && isTribunalLocked,
                    onTap: { selectedSection = section }
                )
            }

            Spacer()

            SidebarIconButton(
                iconName: "gearshape.fill",
                isActive: isSettingsOpen,
                onTap: { isSettingsOpen.toggle() }
            )
            .padding(.bottom, 12)
        }
        .padding(.top, 20)
        .frame(width: 56)
        .frame(maxHeight: .infinity)
        .background(Theme.background)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Theme.border).frame(width: 0.5)
        }
    }

    private var statusDot: some View {
        Group {
            if connectionMonitor.isConnected {
                Circle().fill(Theme.textPrimary)
            } else {
                Circle().stroke(Theme.textFaint, lineWidth: 1)
            }
        }
        .frame(width: 8, height: 8)
    }
}
