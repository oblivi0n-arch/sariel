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

    private var isValid: Bool {
        !trimmedUsername.isEmpty
    }

    var body: some View {
        VStack(spacing: 32) {
            Text(L10n.Wizard.nicknamePrompt)
                .font(Theme.voiceFont)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            TextField(L10n.Settings.usernamePlaceholder, text: $username)
                .textFieldStyle(.plain)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(10)
                .background(Theme.fieldBackground)
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
                    .onHover { hovering in isBackHovering = hovering }

                Text(L10n.Onboarding.next)
                    .font(Typography.label)
                    .foregroundStyle(isValid ? (isNextHovering ? Theme.textPrimary : Theme.textMuted) : Theme.textFaint)
                    .onTapGesture { if isValid { onNext() } }
                    .onHover { hovering in isNextHovering = hovering }
                    .allowsHitTesting(isValid)
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

    static var back: String {
        switch L10n.lang {
        case .en: return "back"
        case .pl: return "wstecz"
        }
    }
}
