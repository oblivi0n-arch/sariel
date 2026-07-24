import SwiftUI

struct DashboardStatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
                .tracking(1)

            Text(value)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }
}
