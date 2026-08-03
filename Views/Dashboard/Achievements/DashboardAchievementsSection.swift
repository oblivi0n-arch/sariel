import SwiftUI

struct DashboardAchievementsSection: View {
    let unlocks: [AchievementUnlock]
    let onTapIcon: (AchievementUnlock) -> Void
    let onTapHeader: () -> Void

    @State private var isHoveringHeader = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTapHeader) {
                HStack(spacing: 6) {
                    Text(L10n.Dashboard.achievementsLabel)
                        .font(Typography.caption)
                        .foregroundStyle(isHoveringHeader ? Theme.textMuted : Theme.textFaint)
                        .tracking(1)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(Typography.iconSmall)
                        .foregroundStyle(isHoveringHeader ? Theme.textMuted : Theme.textFaint)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .trackHover($isHoveringHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(unlocks) { unlock in
                        AchievementIconView(unlock: unlock, onTap: { onTapIcon(unlock) })
                    }
                }
            }
        }
    }
}
