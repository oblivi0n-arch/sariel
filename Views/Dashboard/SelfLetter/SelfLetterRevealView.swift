import SwiftUI
import SwiftData

private enum RevealStage {
    case sealed
    case revealing
    case revealed
}

struct SelfLetterRevealView: View {
    @Bindable var letter: SelfLetter
    let onDismiss: () -> Void
    let achievementService: AchievementService

    @Environment(\.modelContext) private var modelContext
    @State private var stage: RevealStage = .sealed

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch stage {
            case .sealed:
                VStack(spacing: 16) {
                    Image(systemName: "seal.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.textMuted)

                    Text(L10n.SelfLetterReveal.waitedText(daysWaited))
                        .font(Typography.label)
                        .foregroundStyle(Theme.textFaint)

                    Text(L10n.SelfLetterReveal.tapToOpen)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture(perform: breakSeal)

            case .revealing, .revealed:
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer()
                        if stage == .revealed {
                            Button(action: onDismiss) {
                                Image(systemName: "xmark")
                                    .font(Typography.iconButton)
                                    .foregroundStyle(Theme.textFaint)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let title = letter.title, !title.isEmpty {
                                Text(title)
                                    .font(Typography.sectionTitle)
                                    .foregroundStyle(Theme.textPrimary)
                            }

                            RevealingText(
                                fullText: letter.content,
                                font: Theme.voiceFont,
                                color: Theme.textPrimary,
                                charsPerSecond: 60,
                                onComplete: { stage = .revealed }
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if stage == .revealed {
                        HStack(spacing: 4) {
                            Text(L10n.SelfLetterReveal.writtenOnLabel)
                            Text(letter.createdAt, style: .date)
                        }
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                    }
                }
                .padding(24)
            }
        }
    }

    private func breakSeal() {
        letter.letterStatus = .opened
        letter.openedAt = Date()
        try? modelContext.save()
        
        achievementService.checkSelfLetterFirstOpened(modelContext: modelContext)

        withAnimation(.easeOut(duration: 0.3)) {
            stage = .revealing
        }
    }
    
    private var daysWaited: Int {
        max(0, Calendar.current.dateComponents([.day], from: letter.createdAt, to: Date()).day ?? 0)
    }
}

extension L10n {
    enum SelfLetterReveal {
        static func waitedText(_ days: Int) -> String {
            switch lang {
            case .en: return days == 1 ? "waited 1 day" : "waited \(days) days"
            case .pl: return days == 1 ? "czekał 1 dzień" : "czekał \(days) dni"
            }
        }

        static var tapToOpen: String {
            switch lang {
            case .en: return "tap to open"
            case .pl: return "dotknij, by otworzyć"
            }
        }

        static var writtenOnLabel: String {
            switch lang {
            case .en: return "written on"
            case .pl: return "napisano"
            }
        }
    }
}
