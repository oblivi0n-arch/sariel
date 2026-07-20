import Foundation

struct OnboardingScreen: Identifiable {
    let id: Int
    let text: String
    let footnote: String?
    let buttonLabel: String

    init(id: Int, text: String, footnote: String? = nil, buttonLabel: String = "next") {
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
                    ? "let's try again, yeah?"
                    : "You're here because something isn't sitting right."
            ),
            OnboardingScreen(
                id: 1,
                text: "What do you expect from this app? To fix you? I'm afraid it will break you. But that's the point. To become the star, you must burn."
            ),
            OnboardingScreen(
                id: 2,
                text: "Everything you write stays on this device. Nothing is ever sent anywhere.",
                footnote: "Sariel is not therapy, counseling, or a crisis service, and was never built as a substitute for one. If you are struggling or in crisis, please reach out to a mental health professional or a real human you trust. Your life is valuable 🤍",
                buttonLabel: "Face yourself"
            )
        ]
    }
}
