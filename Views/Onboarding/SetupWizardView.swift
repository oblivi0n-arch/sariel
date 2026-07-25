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
                LanguageStepView(onNext: { currentStep = .nickname })
            case .nickname:
                NicknameStepView(
                    onNext: { currentStep = .ollama },
                    onBack: { currentStep = .language }
                )
            case .ollama:
                OllamaStepView(
                    onFinish: onFinished,
                    onBack: { currentStep = .nickname }
                )
            }
        }
    }
}
