import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @State private var ringScale: [CGFloat] = [0.15, 0.15, 0.15]
    @State private var ringOpacity: [Double] = [0, 0, 0]
    @State private var textOpacity: Double = 0

    private let baseRingSize: CGFloat = 60

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Theme.background.ignoresSafeArea()

                Group {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Theme.textPrimary, lineWidth: 1)
                            .frame(width: baseRingSize, height: baseRingSize)
                            .scaleEffect(ringScale[i])
                            .opacity(ringOpacity[i])
                    }

                    VStack(spacing: 8) {
                        Text("Sariel")
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.textPrimary)

                        Text(L10n.Splash.tagline)
                            .font(Typography.label)
                            .foregroundStyle(Theme.textMuted)
                    }
                    .opacity(textOpacity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                let targetScale = targetScale(for: geo.size)

                for i in 0..<3 {
                    withAnimation(.easeOut(duration: 0.5).delay(Double(i) * 0.1)) {
                        ringOpacity[i] = 0.5
                    }
                }
                withAnimation(.easeIn(duration: 0.5)) {
                    textOpacity = 1
                }

                for i in 0..<3 {
                    withAnimation(.easeOut(duration: 1.2).delay(0.4 + Double(i) * 0.25)) {
                        ringScale[i] = targetScale
                        ringOpacity[i] = 0
                    }
                }

                Task {
                    try? await Task.sleep(nanoseconds: 2_200_000_000)
                    onFinished()
                }
            }
        }
    }

    private func targetScale(for size: CGSize) -> CGFloat {
        let diagonal = sqrt(size.width * size.width + size.height * size.height)
        return diagonal / baseRingSize
    }
}

extension L10n {
    enum Splash {
        static var tagline: String {
            switch lang {
            case .en: return "to become the star, you must burn"
            case .pl: return "żeby stać się gwiazdą, musisz spłonąć"
            }
        }
    }
}
