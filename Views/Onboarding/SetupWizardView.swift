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

struct NicknameStepView: View {
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("TODO: nick")
                .foregroundStyle(Theme.textPrimary)
            Text("dalej")
                .foregroundStyle(Theme.textMuted)
                .onTapGesture(perform: onNext)
        }
    }
}

struct OllamaStepView: View {
    let onFinish: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("TODO: ollama")
                .foregroundStyle(Theme.textPrimary)
            Text("zakończ")
                .foregroundStyle(Theme.textMuted)
                .onTapGesture(perform: onFinish)
        }
    }
}
