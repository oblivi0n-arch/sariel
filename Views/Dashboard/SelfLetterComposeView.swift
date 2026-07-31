import SwiftUI
import SwiftData

private enum ComposeStage {
    case writing
    case sealing
}

struct SelfLetterComposeView: View {
    @Environment(\.modelContext) private var modelContext
    let onDismiss: () -> Void

    @State private var stage: ComposeStage = .writing
    @State private var draftContent: String = ""
    @State private var selectedDelay: SelfLetterDelay = .oneWeek

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch stage {
            case .writing:
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(Typography.iconButton)
                                .foregroundStyle(Theme.textFaint)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(20)

                    ZStack(alignment: .topLeading) {
                        if draftContent.isEmpty {
                            Text(L10n.SelfLetterCompose.writingPlaceholder)
                                .font(Theme.voiceFont)
                                .foregroundStyle(Theme.textFaint)
                                .padding(.horizontal, 14)
                                .padding(.top, 12)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $draftContent)
                            .font(Theme.voiceFont)
                            .foregroundStyle(Theme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 9)
                            .padding(.top, 10)
                    }
                    .padding(.horizontal, 16)

                    HStack {
                        Spacer()
                        Button(action: { stage = .sealing }) {
                            Text(L10n.SelfLetterCompose.nextButton)
                                .font(Typography.label)
                                .foregroundStyle(Theme.textPrimary)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                        .disabled(draftContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(20)
                }
            case .sealing:
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Button(action: { stage = .writing }) {
                            Image(systemName: "chevron.left")
                                .font(Typography.iconButton)
                                .foregroundStyle(Theme.textFaint)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(20)

                    Text(L10n.SelfLetterCompose.delayPickerLabel)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                        .textCase(.uppercase)
                        .kerning(0.5)
                        .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(SelfLetterDelay.allCases, id: \.self) { delay in
                            delayOption(delay)
                        }
                    }
                    .padding(20)

                    Spacer()

                    HStack {
                        Spacer()
                        Button(action: sealLetter) {
                            Text(L10n.SelfLetterCompose.sealButton)
                                .font(Typography.label)
                                .foregroundStyle(Theme.background)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Theme.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                }
            }
        }
    }
    
    private func delayOption(_ delay: SelfLetterDelay) -> some View {
        let isSelected = selectedDelay == delay
        return Text(delay.displayName)
            .font(Typography.label)
            .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Theme.borderStrong : Theme.border, lineWidth: 0.5))
            .contentShape(Rectangle())
            .onTapGesture { selectedDelay = delay }
    }

    private func sealLetter() {
        let letter = SelfLetter(
            content: draftContent,
            openDate: selectedDelay.openDate()
        )
        modelContext.insert(letter)
        try? modelContext.save()
        onDismiss()
    }
}

extension L10n {
    enum SelfLetterCompose {
        static var writingPlaceholder: String {
            switch lang {
            case .en: return "Dear me..."
            case .pl: return "Drogi ja..."
            }
        }

        static var nextButton: String {
            switch lang {
            case .en: return "Next"
            case .pl: return "Dalej"
            }
        }
        
        static var delayPickerLabel: String {
            switch lang {
            case .en: return "when should you read this"
            case .pl: return "kiedy masz to przeczytać"
            }
        }

        static var sealButton: String {
            switch lang {
            case .en: return "Seal it"
            case .pl: return "Zapieczętuj"
            }
        }
    }
}
