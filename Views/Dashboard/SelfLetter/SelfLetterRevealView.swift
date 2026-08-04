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
    @State private var isHoveringSeal = false
    @State private var isHoveringClose = false
    @State private var isSealIconVisible = false
    @State private var isSealTitleStarted = false
    @State private var isSealRestVisible = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch stage {
            case .sealed:
                ZStack {
                    AmbientRingsView()

                    VStack(spacing: 22) {
                        Image(systemName: "envelope")
                            .font(.system(size: 34))
                            .foregroundStyle(Theme.textMuted)
                            .opacity(isSealIconVisible ? 1 : 0)
                            .scaleEffect(isSealIconVisible ? 1 : 0.7)

                        Group {
                            if isSealTitleStarted {
                                RevealingText(
                                    fullText: L10n.SelfLetterReveal.sealedTitle,
                                    font: Theme.voiceFont,
                                    color: Theme.textPrimary,
                                    charsPerSecond: 22,
                                    onComplete: revealSealRest
                                )
                            } else {
                                Text(" ")
                                    .font(Theme.voiceFont)
                            }
                        }
                        .multilineTextAlignment(.center)

                        VStack(spacing: 10) {
                            Text(L10n.SelfLetterReveal.waitedText(daysWaited))
                                .font(Typography.label)
                                .foregroundStyle(Theme.textFaint)

                            Text(L10n.SelfLetterReveal.tapToOpen)
                                .font(Typography.caption)
                                .foregroundStyle(isHoveringSeal ? Theme.textMuted : Theme.textFaint)
                        }
                        .opacity(isSealRestVisible ? 1 : 0)
                    }
                    .frame(maxWidth: 320)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture(perform: breakSeal)
                .trackHover($isHoveringSeal)
            case .revealing, .revealed:
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer()
                        if stage == .revealed {
                            Button(action: onDismiss) {
                                Image(systemName: "xmark")
                                    .font(Typography.iconButton)
                                    .foregroundStyle(isHoveringClose ? Theme.textMuted : Theme.textFaint)
                                    .frame(width: 28, height: 28)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .trackHover($isHoveringClose)
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
        .onAppear(perform: startSealSequence)
    }
    
    private func startSealSequence() {
        withAnimation(.easeOut(duration: 0.5)) {
            isSealIconVisible = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            isSealTitleStarted = true
        }
    }

    private func revealSealRest() {
        withAnimation(.easeIn(duration: 0.4)) {
            isSealRestVisible = true
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
        static var sealedTitle: String {
            switch lang {
            case .en: return "Sealed by someone you no longer are."
            case .pl: return "Zapieczętowane przez kogoś, kim już nie jesteś."
            }
        }
        
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
