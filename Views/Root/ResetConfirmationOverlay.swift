import SwiftUI

struct ResetConfirmationOverlay: View {
    let conversations: Int
    let journalEntries: Int
    let commitments: Int
    let unlockedAchievements: Int
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var typedText: String = ""

    private var isConfirmEnabled: Bool {
        typedText.trimmingCharacters(in: .whitespacesAndNewlines)
            .caseInsensitiveCompare(L10n.Settings.resetConfirmPhrase) == .orderedSame
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onCancel)

            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Settings.resetConfirmTitle)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                Text(L10n.Settings.resetConfirmMessage(
                    conversations: conversations,
                    journalEntries: journalEntries,
                    commitments: commitments,
                    unlockedAchievements: unlockedAchievements
                ))
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textMuted)

                Text(L10n.Settings.resetTypeToConfirmLabel(phrase: L10n.Settings.resetConfirmPhrase))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)

                TextField(L10n.Settings.resetConfirmPhrase, text: $typedText)
                    .textFieldStyle(.plain)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(10)
                    .background(Theme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))

                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text(L10n.Settings.cancelButton)
                            .font(Typography.label)
                            .foregroundStyle(Theme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button(action: onConfirm) {
                        Text(L10n.Settings.resetConfirmButton)
                            .font(Typography.label)
                            .foregroundStyle(Color.red.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.4), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isConfirmEnabled)
                    .opacity(isConfirmEnabled ? 1 : 0.4)
                }
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
