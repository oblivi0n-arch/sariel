import Foundation

struct OnboardingScreen: Identifiable {
    let id: Int
    let text: String
    let footnote: String?
    let buttonLabel: String

    init(id: Int, text: String, footnote: String? = nil, buttonLabel: String = L10n.Onboarding.next) {
        self.id = id
        self.text = text
        self.footnote = footnote
        self.buttonLabel = buttonLabel
    }
}

extension OnboardingScreen {
    static func screens(isPostReset: Bool) -> [OnboardingScreen] {
        [
            OnboardingScreen(
                id: 0,
                text: isPostReset
                    ? L10n.Onboarding.welcomeBack
                    : L10n.Onboarding.welcomeFirst
            ),
            OnboardingScreen(
                id: 1,
                text: L10n.Onboarding.expectationText
            ),
            OnboardingScreen(
                id: 2,
                text: L10n.Onboarding.privacyText,
                footnote: L10n.Onboarding.privacyFootnote,
                buttonLabel: L10n.Onboarding.faceYourself
            )
        ]
    }
}

extension L10n {
    enum Onboarding {
        static var next: String {
            switch lang {
            case .en: return "next"
            case .pl: return "dalej"
            }
        }

        static var faceYourself: String {
            switch lang {
            case .en: return "Face yourself"
            case .pl: return "Spójrz prawdzie w oczy"
            }
        }

        static var welcomeBack: String {
            switch lang {
            case .en: return "let's try again, yeah?"
            case .pl: return "spróbujmy jeszcze raz, dobrze?"
            }
        }

        static var welcomeFirst: String {
            switch lang {
            case .en: return "You're here because something isn't sitting right."
            case .pl: return "Jesteś tu, bo coś Ci nie daje spokoju."
            }
        }

        static var expectationText: String {
            switch lang {
            case .en: return "What do you expect from this app? To fix you? I'm afraid it will break you. But that's the point. To become the star, you must burn."
            case .pl: return "Czego oczekujesz od tej aplikacji? Że Cię naprawi? Obawiam się, że raczej Cię złamie. Ale o to właśnie chodzi. Żeby stać się gwiazdą, musisz spłonąć."
            }
        }

        static var privacyText: String {
            switch lang {
            case .en: return "Everything you write stays on this device. Nothing is ever sent anywhere."
            case .pl: return "Wszystko, co napiszesz, zostaje na tym urządzeniu. Nic nigdy nigdzie nie jest wysyłane."
            }
        }

        static var privacyFootnote: String {
            switch lang {
            case .en: return "Sariel is not therapy, counseling, or a crisis service, and was never built as a substitute for one. If you are struggling or in crisis, please reach out to a mental health professional or a real human you trust. Your life is valuable 🤍"
            case .pl: return "Sariel nie jest terapią, poradnictwem ani serwisem kryzysowym i nigdy nie powstał jako ich zamiennik. Jeśli zmagasz się z trudnościami lub przeżywasz kryzys, zwróć się do specjalisty od zdrowia psychicznego lub prawdziwej, zaufanej osoby. Twoje życie ma wartość 🤍"
            }
        }
    }
}
