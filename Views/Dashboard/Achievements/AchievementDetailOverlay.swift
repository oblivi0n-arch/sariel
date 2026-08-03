import SwiftUI

struct AchievementDetailOverlay: View {
    let unlock: AchievementUnlock
    let onClose: () -> Void

    private var kind: AchievementKind? { unlock.achievementKind }

    private var statusText: String {
        guard let kind else { return "" }
        if unlock.isUnlocked {
            return kind.unlockedDescription
        }
        if kind.isProgressive, unlock.progress > 0, let target = kind.targetCount {
            return L10n.Achievements.progressText(unlock.progress, target)
        }
        return kind.hintText
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onClose)

            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: kind?.symbolName ?? "questionmark")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(unlock.isUnlocked ? Theme.textPrimary : Theme.textFaint)

                Text(unlock.isUnlocked ? (kind?.title ?? "") : L10n.Achievements.lockedTitle)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                Text(statusText)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textMuted)

                if let unlockedAt = unlock.unlockedAt {
                    Text(unlockedAt, style: .date)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                }

                Button(action: onClose) {
                    Text(L10n.Achievements.closeButton)
                        .font(Typography.label)
                        .foregroundStyle(Theme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                        .hoverBorder(cornerRadius: 8)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(maxWidth: 360)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.6), radius: 40, y: 12)
            .onTapGesture {}
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

extension L10n {
    enum Achievements {
        static var lockedTitle: String {
            switch lang {
            case .pl: return "Zablokowane"
            case .en: return "Locked"
            }
        }

        static var closeButton: String {
            switch lang {
            case .pl: return "Zamknij"
            case .en: return "Close"
            }
        }

        static func progressText(_ current: Int, _ target: Int) -> String {
            switch lang {
            case .pl: return "\(current) z \(target)"
            case .en: return "\(current) of \(target)"
            }
        }
    }
}
