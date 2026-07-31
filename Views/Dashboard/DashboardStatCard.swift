import SwiftUI

struct DashboardStatCard: View {
    let label: String
    let value: String
    var icon: String? = nil
    var isAccented: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Group {
            if onTap != nil {
                content.hoverScale()
            } else {
                content
            }
        }
        .onTapGesture { onTap?() }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
                .tracking(1)

            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isAccented ? Theme.textPrimary : Theme.textMuted)
            }

            Text(value)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isAccented ? Theme.borderStrong : Theme.border, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
    }
}
