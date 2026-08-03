import SwiftUI
import SwiftData

private enum ComposeStage {
    case writing
    case sealing
}

private enum ComposeField {
    case title
    case content
}

struct SelfLetterComposeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var letter: SelfLetter
    let onDismiss: () -> Void
    let achievementService: AchievementService

    @State private var stage: ComposeStage = .writing
    @FocusState private var focusedField: ComposeField?
    @State private var selectedDelay: SelfLetterDelay = .oneMonth
    @State private var saveTask: Task<Void, Never>?
    @State private var isHoveringClose = false

    private var titleBinding: Binding<String> {
        Binding(
            get: { letter.title ?? "" },
            set: { letter.title = $0.isEmpty ? nil : $0 }
        )
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch stage {
            case .writing:
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Button(action: closeCompose) {
                            Image(systemName: "xmark")
                                .font(Typography.iconButton)
                                .foregroundStyle(isHoveringClose ? Theme.textMuted : Theme.textFaint)
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .trackHover($isHoveringClose)
                        
                        Spacer()
                    }
                    .padding(20)

                    PlaceholderTextField(
                        placeholder: L10n.SelfLetterCompose.titlePlaceholder,
                        text: titleBinding,
                        font: Typography.title,
                        textColor: Theme.textPrimary
                    )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        .focused($focusedField, equals: .title)
                        .onSubmit { focusedField = .content }
                        .onChange(of: letter.title) { scheduleSave() }

                    ZStack(alignment: .topLeading) {
                        if letter.content.isEmpty {
                            Text(L10n.SelfLetterCompose.writingPlaceholder)
                                .font(Theme.voiceFont)
                                .foregroundStyle(Theme.textFaint)
                                .padding(.horizontal, 14)
                                .padding(.top, 12)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $letter.content)
                            .font(Theme.voiceFont)
                            .foregroundStyle(Theme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 9)
                            .padding(.top, 10)
                            .focused($focusedField, equals: .content)
                            .onChange(of: letter.content) { scheduleSave() }
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
                                .hoverBorder(cornerRadius: 8)
                        }
                        .buttonStyle(.plain)
                        .disabled(letter.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(20)
                    .onAppear { focusedField = .title }
                }
            case .sealing:
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        BackButton(action: { stage = .writing })

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
                            DelayOptionView(
                                delay: delay,
                                isSelected: selectedDelay == delay,
                                onTap: { selectedDelay = delay }
                            )
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
                        .hoverScale()
                    }
                    .padding(20)
                }
            }
        }
        .onDisappear {
            saveTask?.cancel()
            try? modelContext.save()
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            try? modelContext.save()
        }
    }

    private func closeCompose() {
        saveTask?.cancel()
        let isEmpty = letter.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (letter.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        if isEmpty {
            modelContext.delete(letter)
        }
        try? modelContext.save()
        onDismiss()
    }

    private func sealLetter() {
        let trimmedTitle = letter.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        letter.title = (trimmedTitle?.isEmpty ?? true) ? nil : trimmedTitle
        letter.openDate = selectedDelay.openDate()
        letter.letterStatus = .sealed
        try? modelContext.save()
        achievementService.checkSelfLetterFirstSealed(modelContext: modelContext)
        achievementService.checkSelfLetterLongestDelay(modelContext: modelContext)
        onDismiss()
    }
}

private struct DelayOptionView: View {
    let delay: SelfLetterDelay
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(delay.displayName)
            .font(Typography.label)
            .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Theme.borderStrong : Theme.border, lineWidth: 0.5))
            .hoverBorder(cornerRadius: 8)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
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
        
        static var titlePlaceholder: String {
            switch lang {
            case .en: return "Title (optional)"
            case .pl: return "Tytuł (opcjonalnie)"
            }
        }
    }
}
