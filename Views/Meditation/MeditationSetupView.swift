import SwiftUI

struct MeditationSetupView: View {
    let onStart: (String, MeditationDuration) -> Void

    @State private var intention: String = ""
    @State private var selectedDuration: MeditationDuration = .tenMinutes
    @FocusState private var isIntentionFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.MeditationSetup.intentionLabel)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
                    .textCase(.uppercase)
                    .kerning(0.5)

                PlaceholderTextField(
                    placeholder: L10n.MeditationSetup.intentionPlaceholder,
                    text: $intention,
                    font: Typography.title,
                    textColor: Theme.textPrimary
                )
                .padding(.top, 8)
                .padding(.bottom, 24)
                .focused($isIntentionFocused)

                Text(L10n.MeditationSetup.durationLabel)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
                    .textCase(.uppercase)
                    .kerning(0.5)

                HStack(spacing: 8) {
                    ForEach(MeditationDuration.allCases, id: \.self) { duration in
                        durationOption(duration)
                    }
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: 480)

            Spacer()

            HStack {
                Spacer()
                Button(action: startSession) {
                    Text(L10n.MeditationSetup.startButton)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .onAppear { isIntentionFocused = true }
    }

    private func durationOption(_ duration: MeditationDuration) -> some View {
        let isSelected = selectedDuration == duration
        return Text(duration.displayName)
            .font(Typography.label)
            .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Theme.borderStrong : Theme.border, lineWidth: 0.5))
            .contentShape(Rectangle())
            .onTapGesture { selectedDuration = duration }
    }

    private func startSession() {
        onStart(intention.trimmingCharacters(in: .whitespacesAndNewlines), selectedDuration)
    }
}

extension L10n {
    enum MeditationSetup {
        static var intentionLabel: String {
            switch lang {
            case .en: return "INTENTION"
            case .pl: return "INTENCJA"
            }
        }

        static var intentionPlaceholder: String {
            switch lang {
            case .en: return "What are you sitting with today? (optional)"
            case .pl: return "Z czym dziś siadasz? (opcjonalnie)"
            }
        }

        static var durationLabel: String {
            switch lang {
            case .en: return "DURATION"
            case .pl: return "CZAS"
            }
        }

        static var startButton: String {
            switch lang {
            case .en: return "Start"
            case .pl: return "Zacznij"
            }
        }
    }
}
