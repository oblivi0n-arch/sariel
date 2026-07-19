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
                footnote: "If this ever becomes a real crisis — not discomfort, but danger — this mirror puts itself down and speaks to you plainly.",
                buttonLabel: "Face yourself"
            )
        ]
    }
}
