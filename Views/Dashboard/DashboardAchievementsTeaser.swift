import SwiftUI

struct DashboardAchievementsTeaser: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .font(Typography.icon)
                    .foregroundStyle(Theme.textFaint)

                Text(L10n.Dashboard.achievementsLabel)
                    .font(Typography.label)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.iconSmall)
                    .foregroundStyle(Theme.textFaint)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}
