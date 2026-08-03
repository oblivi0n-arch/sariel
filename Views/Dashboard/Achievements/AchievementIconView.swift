import SwiftUI

struct AchievementIconView: View {
    let unlock: AchievementUnlock
    let onTap: () -> Void

    private var kind: AchievementKind? { unlock.achievementKind }

    private var progressFraction: Double {
        guard let kind, let target = kind.targetCount, target > 0 else { return 0 }
        return min(Double(unlock.progress) / Double(target), 1.0)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if unlock.isUnlocked {
                    Circle()
                        .stroke(Theme.border, lineWidth: 1)
                } else if kind?.isProgressive == true, unlock.progress > 0 {
                    Circle()
                        .trim(from: 0, to: progressFraction)
                        .stroke(Theme.borderStrong, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }

                Image(systemName: kind?.symbolName ?? "questionmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(unlock.isUnlocked ? Theme.textPrimary : Theme.textFaint)
            }
            .frame(width: 44, height: 44)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .hoverBorder(Circle())
        }
        .buttonStyle(.plain)
    }
}
