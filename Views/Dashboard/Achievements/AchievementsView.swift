import SwiftUI
import SwiftData

struct AchievementsView: View {
    let unlocks: [AchievementUnlock]
    let onBack: () -> Void

    @State private var selectedUnlock: AchievementUnlock?

    private let columns = [
        GridItem(.adaptive(minimum: 44, maximum: 44), spacing: 10)
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                header

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(unlocks) { unlock in
                            AchievementIconView(unlock: unlock, onTap: { selectedUnlock = unlock })
                        }
                    }
                }
            }
            .padding(28)

            if let selectedUnlock {
                AchievementDetailOverlay(unlock: selectedUnlock, onClose: { self.selectedUnlock = nil })
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            BackButton(action: onBack)

            Text(L10n.Dashboard.achievementsLabel)
                .font(Typography.title)
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
