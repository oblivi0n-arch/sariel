import SwiftUI

enum SetupStep: Int, CaseIterable {
    case language
    case nickname
    case ollama
}

struct SetupWizardView: View {
    let onFinished: () -> Void
    @State private var currentStep: SetupStep = .language

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch currentStep {
            case .language:
                LanguageStepView(
                    onNext: { withAnimation(.easeInOut(duration: 0.4)) { currentStep = .nickname }}
                )
                .transition(.opacity)
            case .nickname:
                NicknameStepView(
                    onNext: { withAnimation(.easeInOut(duration: 0.4)) { currentStep = .ollama }},
                    onBack: { withAnimation(.easeInOut(duration: 0.4)) { currentStep = .language }}
                )
                .transition(.opacity)
            case .ollama:
                OllamaStepView(
                    onFinish: onFinished,
                    onBack: { withAnimation(.easeInOut(duration: 0.4)) {currentStep = .nickname }}
                )
                .transition(.opacity)
            }
        }
    }
}
