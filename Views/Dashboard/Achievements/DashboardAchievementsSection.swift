import SwiftUI

struct DashboardAchievementsSection: View {
    let unlocks: [AchievementUnlock]
    let onTapIcon: (AchievementUnlock) -> Void
    let onTapHeader: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTapHeader) {
                HStack(spacing: 6) {
                    Text(L10n.Dashboard.achievementsLabel)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                        .tracking(1)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(Typography.iconSmall)
                        .foregroundStyle(Theme.textFaint)
                }
            }
            .buttonStyle(.plain)

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
