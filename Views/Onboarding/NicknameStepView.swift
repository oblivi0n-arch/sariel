import SwiftUI

struct NicknameStepView: View {
    let onNext: () -> Void
    let onBack: () -> Void

    @AppStorage("username") private var username: String = ""
    @State private var isNextHovering = false
    @State private var isBackHovering = false

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var nextLabel: String {
        trimmedUsername.isEmpty ? L10n.Wizard.skipForNow : L10n.Onboarding.next
    }

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 6) {
                Text(L10n.Wizard.nicknamePrompt)
                    .font(Theme.voiceFont)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(L10n.Wizard.nicknameOptionalLabel)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
            }

            PlaceholderTextField(placeholder: L10n.Settings.usernamePlaceholder, text: $username)
                .multilineTextAlignment(.center)
                .padding(10)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                .frame(maxWidth: 240)
                .onChange(of: username) { _, newValue in
                    if newValue.count > AppLimits.maxUsernameLength {
                        username = String(newValue.prefix(AppLimits.maxUsernameLength))
                    }
                }

            Text("\(username.count)/\(AppLimits.maxUsernameLength)")
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)

            HStack(spacing: 24) {
                Text(L10n.Wizard.back)
                    .font(Typography.label)
                    .foregroundStyle(isBackHovering ? Theme.textPrimary : Theme.textMuted)
                    .onTapGesture(perform: onBack)
                    .trackHover($isBackHovering)

                Text(nextLabel)
                    .font(Typography.label)
                    .foregroundStyle(isNextHovering ? Theme.textPrimary : Theme.textMuted)
                    .onTapGesture(perform: onNext)
                    .trackHover($isNextHovering)
            }
            .padding(.top, 24)
        }
        .frame(maxWidth: 420)
    }
}

extension L10n.Wizard {
    static var nicknamePrompt: String {
        switch L10n.lang {
        case .en: return "What should I call you?"
        case .pl: return "Jak mam się do Ciebie zwracać?"
        }
    }

    static var nicknameOptionalLabel: String {
        switch L10n.lang {
        case .en: return "(optional)"
        case .pl: return "(opcjonalne)"
        }
    }

    static var back: String {
        switch L10n.lang {
        case .en: return "back"
        case .pl: return "wstecz"
        }
    }
}
