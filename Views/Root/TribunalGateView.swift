import SwiftUI

struct TribunalGateView: View {
    let pendingCount: Int
    let onFaceTribunal: () -> Void
    let onDismiss: () -> Void

    @State private var isDismissHovering = false
    @State private var isIconVisible = false
    @State private var isTitleStarted = false
    @State private var isRestVisible = false
    @State private var isHoveringFace = false

    private var titleText: String {
        L10n.TribunalGate.title
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "seal")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.tribunalAccent.opacity(0.85))
                    .opacity(isIconVisible ? 1 : 0)
                    .scaleEffect(isIconVisible ? 1 : 0.7)

                Group {
                    if isTitleStarted {
                        RevealingText(
                            fullText: titleText,
                            font: Theme.voiceFont,
                            color: Theme.textPrimary,
                            charsPerSecond: 30,
                            onComplete: { revealRest() }
                        )
                    } else {
                        Text(" ")
                            .font(Theme.voiceFont)
                    }
                }
                .multilineTextAlignment(.center)

                Group {
                    Text(L10n.TribunalGate.pendingMessage(count: pendingCount))
                        .font(Typography.label)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)

                    Button(action: onFaceTribunal) {
                        Text(L10n.Tribunal.faceTheTribunal)
                            .font(Typography.label)
                            .foregroundStyle(Theme.tribunalAccent.opacity(0.9))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Theme.tribunalAccent.opacity(isHoveringFace ? 0.18 : 0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.tribunalAccent.opacity(isHoveringFace ? 0.7 : 0.4), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .trackHover($isHoveringFace)
                    .padding(.top, 8)

                    Text(L10n.TribunalGate.avoidLonger)
                        .font(Typography.label)
                        .foregroundStyle(isDismissHovering ? Theme.textPrimary : Theme.textMuted)
                        .onTapGesture(perform: onDismiss)
                        .trackHover($isDismissHovering)
                }
                .opacity(isRestVisible ? 1 : 0)
            }
            .frame(maxWidth: 380)
        }
        .onAppear { startSequence() }
    }

    private func startSequence() {
        withAnimation(.easeOut(duration: 0.5)) {
            isIconVisible = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            isTitleStarted = true
        }
    }

    private func revealRest() {
        withAnimation(.easeIn(duration: 0.4)) {
            isRestVisible = true
        }
    }
}

extension L10n {
    enum TribunalGate {
        static var title: String {
            switch lang {
            case .en: return "The Tribunal awaits."
            case .pl: return "Trybunał czeka."
            }
        }

        static var avoidLonger: String {
            switch lang {
            case .en: return "I'll avoid this a little longer"
            case .pl: return "Jeszcze trochę to odłożę"
            }
        }

        static func pendingMessage(count: Int) -> String {
            switch lang {
            case .en:
                return "\(count) commitment\(count == 1 ? "" : "s") await\(count == 1 ? "s" : "") trial. It will not go away on its own."
            case .pl:
                let lastDigit = count % 10
                let lastTwoDigits = count % 100
                let noun: String
                let verb: String
                if count == 1 {
                    noun = "zobowiązanie"; verb = "czeka"
                } else if (2...4).contains(lastDigit) && !(12...14).contains(lastTwoDigits) {
                    noun = "zobowiązania"; verb = "czekają"
                } else {
                    noun = "zobowiązań"; verb = "czeka"
                }
                return "\(count) \(noun) \(verb) na proces. Samo nie zniknie."
            }
        }
    }
}
