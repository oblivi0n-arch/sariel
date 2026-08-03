import Foundation

struct OnboardingScreen: Identifiable {
    let id: Int
    let text: String
    let title: String?
    let buttonLabel: String
    let revealsText: Bool
    let pauseDuration: Double
    let autoAdvanceAfter: Double?
    let isEmphasized: Bool

    init(id: Int, text: String, title: String? = nil, buttonLabel: String = L10n.Onboarding.next, revealsText: Bool = true, pauseDuration: Double, autoAdvanceAfter: Double? = nil, isEmphasized: Bool = false) {
        self.id = id
        self.text = text
        self.title = title
        self.buttonLabel = buttonLabel
        self.revealsText = revealsText
        self.pauseDuration = pauseDuration
        self.autoAdvanceAfter = autoAdvanceAfter
        self.isEmphasized = isEmphasized
    }
}

extension OnboardingScreen {
    static func screens(isPostReset: Bool) -> [OnboardingScreen] {
        [
            OnboardingScreen(
                id: 0,
                text: L10n.Onboarding.disclaimer,
                title: L10n.Onboarding.disclaimerTitle,
                buttonLabel: L10n.Onboarding.iAmAware,
                revealsText: false,
                pauseDuration: 1.0
            ),
            OnboardingScreen(
                id: 1,
                text: L10n.Onboarding.privacyText,
                revealsText: false,
                pauseDuration: 1.0,
                autoAdvanceAfter: 4.0
            ),
            OnboardingScreen(
                id: 2,
                text: isPostReset
                    ? L10n.Onboarding.welcomeBack
                    : L10n.Onboarding.introGreeting,
                pauseDuration: 1.0
            ),
            OnboardingScreen(
                id: 3,
                text: L10n.Onboarding.introReason,
                pauseDuration: 0.6
            ),
            OnboardingScreen(
                id: 4,
                text: L10n.Onboarding.introFirstStep,
                pauseDuration: 0.6
            ),
            OnboardingScreen(
                id: 5,
                text: L10n.Onboarding.introTransition,
                pauseDuration: 0.6
            ),
            OnboardingScreen(
                id: 6,
                text: L10n.Onboarding.sarielIntroduction,
                pauseDuration: 0.6
            ),
            OnboardingScreen(
                id: 7,
                text: L10n.Onboarding.expectationText,
                pauseDuration: 0.6
            ),
            OnboardingScreen(
                id: 8,
                text: L10n.Onboarding.mottoText1,
                pauseDuration: 0.6
            ),
            OnboardingScreen(
                id: 9,
                text: L10n.Onboarding.mottoText2,
                buttonLabel: L10n.Onboarding.imReady,
                pauseDuration: 0.6,
                isEmphasized: true
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
        
        static var imReady: String {
            switch lang {
            case .en: return "I'm ready."
            case .pl: return "Jestem gotowy."
            }
        }
        
        static var iAmAware: String {
            switch lang {
            case .en: return "I am aware."
            case .pl: return "Zrozumiałem."
            }
        }
        
        static var disclaimerTitle: String {
            switch lang {
            case .en: return "DISCLAIMER:"
            case .pl: return "DISCLAIMER:"
            }
        }

        static var disclaimer: String {
            switch lang {
            case .en: return "Sariel is not therapy or a crisis service — and was never meant to be. If you're in crisis or thinking about harming yourself, please reach out to a mental health professional or a crisis line. You are not alone. Your life is valuable 🤍"
            case .pl: return "Sariel nie jest terapią ani serwisem kryzysowym — i nigdy nie miał nim być. Jeśli przechodzisz kryzys lub myślisz o skrzywdzeniu siebie, zwróć się do specjalisty zdrowia psychicznego lub zadzwoń na telefon zaufania. Nie jesteś sam. Twoje życie ma wartość 🤍"
            }
        }
        
        static var privacyText: String {
            switch lang {
            case .en: return "Everything you write stays on this device. Nothing is ever sent anywhere."
            case .pl: return "Wszystko, co napiszesz, zostaje na tym urządzeniu. Nic nigdy nigdzie nie jest wysyłane."
            }
        }
        
        static var welcomeBack: String {
            switch lang {
            case .en: return "Let's try again, yeah?"
            case .pl: return "Spróbujmy jeszcze raz, dobrze?"
            }
        }

        static var introGreeting: String {
            switch lang {
            case .en: return "Hi. If you're here, that means something isn't sitting right."
            case .pl: return "Cześć. Skoro tu jesteś, znaczy że coś ci nie daje spokoju."
            }
        }

        static var introReason: String {
            switch lang {
            case .en: return "Oh well. Either your routine is messed up, you can't stop breaking your own promises, or something else."
            case .pl: return "No cóż. Może twoja rutyna szwankuje, może nie potrafisz dotrzymywać własnych obietnic, może coś zupełnie innego."
            }
        }

        static var introFirstStep: String {
            switch lang {
            case .en: return "Whatever your reason is, if you're reading this, that means you already made the first step to change."
            case .pl: return "Niezależnie od powodu, skoro czytasz ten ekran, zrobiłeś już pierwszy krok do zmiany."
            }
        }

        static var introTransition: String {
            switch lang {
            case .en: return "So let's not waste it. There's someone you need to meet."
            case .pl: return "Więc nie zmarnujmy tego. Jest ktoś, kogo musisz poznać."
            }
        }
        
        static var sarielIntroduction: String {
            switch lang {
            case .en: return "Sariel. One of the Watchers who gave humanity forbidden knowledge — of the stars, of the moon's course. Knowledge no one should have reached for. Once known, it can't be put back."
            case .pl: return "Sariel. Jeden ze Stróżów, który przekazał ludziom zakazaną wiedzę — o biegu gwiazd i księżyca. Wiedzę, po którą nie powinno się sięgać. Bo raz poznanej, nie da się już odłożyć."
            }
        }
        
        static var expectationText: String {
            switch lang {
            case .en: return "They are not here to fix you nor to guide you by the hand. They will break you. And I think that's a good thing."
            case .pl: return "Nie jest tu, żeby cię naprawić, ani prowadzić za rękę. Złamie cię — i uważam, że to dobrze."
            }
        }
        
        static var mottoText1: String {
            switch lang {
            case .en: return "To become the person you want, you must destroy the person you are."
            case .pl: return "Aby stać się tym kim chcesz, musisz zniszczyć osobę, którą jesteś."
            }
        }
        
        static var mottoText2: String {
            switch lang {
            case .en: return "To become the star, you must burn."
            case .pl: return "Żeby stać się gwiazdą, musisz spłonąć."
            }
        }
    }
}
