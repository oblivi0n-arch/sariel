import Foundation

struct OnboardingScreen: Identifiable {
    let id: Int
    let text: String
    let footnote: String?   // TODO: currently unused - kept for potential future use
    let buttonLabel: String
    let revealsText: Bool
    let pauseDuration: Double

    init(id: Int, text: String, footnote: String? = nil, buttonLabel: String = L10n.Onboarding.next, revealsText: Bool = true, pauseDuration: Double) {
        self.id = id
        self.text = text
        self.footnote = footnote
        self.buttonLabel = buttonLabel
        self.revealsText = revealsText
        self.pauseDuration = pauseDuration
    }
}

extension OnboardingScreen {
    static func screens(isPostReset: Bool) -> [OnboardingScreen] {
        [
            OnboardingScreen(
                id: 0,
                text: L10n.Onboarding.disclaimer,
                buttonLabel: L10n.Onboarding.iAmAware,
                revealsText: false,
                pauseDuration: 1.0
            ),
            OnboardingScreen(
                id: 1,
                text: isPostReset
                    ? L10n.Onboarding.welcomeBack
                    : L10n.Onboarding.welcomeFirst,
                pauseDuration: 1.0
            ),
            OnboardingScreen(
                id: 2,
                text: L10n.Onboarding.beforeYouStart,
                pauseDuration: 0.6
            ),
            OnboardingScreen(
                id: 3,
                text: L10n.Onboarding.sarielIntroduction,
                pauseDuration: 0.6
            ),
            OnboardingScreen(
                id: 4,
                text: L10n.Onboarding.expectationText,
                pauseDuration: 0.6
            ),
            OnboardingScreen(
                id: 5,
                text: L10n.Onboarding.privacyText,
                pauseDuration: 0.6
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

        static var disclaimer: String {
            switch lang {
            case .en: return "Sariel is not therapy, counseling, or a crisis service, and was never built as a substitute for one. If you are struggling or in crisis, please reach out to a mental health professional or a real human you trust. Your life is valuable 🤍"
            case .pl: return "Sariel nie jest terapią, poradnictwem ani serwisem kryzysowym i nigdy nie powstał jako ich zamiennik. Jeśli zmagasz się z trudnościami lub przeżywasz kryzys, zwróć się do specjalisty od zdrowia psychicznego lub prawdziwej, zaufanej osoby. Twoje życie ma wartość 🤍"
            }
        }
        
        static var sarielIntroduction: String {
            switch lang {
            case .en: return "Sariel. One of the Watchers who gave humanity forbidden knowledge — of the stars, of the moon's course. Knowledge no one should have reached for. Once known, it can't be put back."
            case .pl: return "Sariel. Jeden ze Stróżów, który przekazał ludziom zakazaną wiedzę — o biegu gwiazd i księżyca. Wiedzę, po którą nie powinno się sięgać. Bo raz poznanej, nie da się już odłożyć."
            }
        }
        
        static var beforeYouStart: String {
            switch lang {
            case .en: return "Before we go any further, I want you to meet someone."
            case .pl: return "Przed rozpoczęciem, chciałbym Tobie kogoś przedstawić."
            }
        }
        
        static var iAmAware: String {
            switch lang {
            case .en: return "I am aware."
            case .pl: return "Zrozumiałem."
            }
        }
    }
}
