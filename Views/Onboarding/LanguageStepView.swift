import SwiftUI

struct LanguageStepView: View {
    let onNext: () -> Void

    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var isButtonHovering = false

    var body: some View {
        VStack(spacing: 32) {
            Text(L10n.Wizard.languagePrompt)
                .font(Theme.voiceFont)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    LanguageOptionButton(language: .pl, label: "PL")
                    LanguageOptionButton(language: .en, label: "EN")
                }

                Text(L10n.Wizard.languageOllamaHint)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
                    .multilineTextAlignment(.center)
            }

            Text(L10n.Onboarding.next)
                .font(Typography.label)
                .foregroundStyle(isButtonHovering ? Theme.textPrimary : Theme.textMuted)
                .onTapGesture(perform: onNext)
                .trackHover($isButtonHovering)
                .padding(.top, 24)
        }
        .frame(maxWidth: 420)
    }
}

extension L10n {
    enum Wizard {
        static var languagePrompt: String {
            switch lang {
            case .en: return "First — which language do you want to continue in?"
            case .pl: return "Najpierw — w jakim języku chcesz kontynuować?"
            }
        }
        
        static var languageOllamaHint: String {
            switch lang {
            case .en: return "Ollama tends to work best in English, regardless of what you pick here."
            case .pl: return "Ollama działa najlepiej po angielsku, niezależnie od wyboru powyżej."
            }
        }
    }
}
