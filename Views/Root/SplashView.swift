import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @State private var ringScale: [CGFloat] = [0.3, 0.3, 0.3]
    @State private var ringOpacity: [Double] = [0.5, 0.5, 0.5]
    @State private var textOpacity: Double = 0
    @State private var isVisible = true

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

                        Text("mirror to your own thoughts")
                            .font(Typography.label)
                            .foregroundStyle(Theme.textMuted)
                    }
                    .opacity(textOpacity)
                }
                .opacity(isVisible ? 1 : 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                let targetScale = targetScale(for: geo.size)

                for i in 0..<3 {
                    withAnimation(.easeOut(duration: 1.2).delay(Double(i) * 0.25)) {
                        ringScale[i] = targetScale
                        ringOpacity[i] = 0
                    }
                }
                withAnimation(.easeIn(duration: 0.6).delay(0.15)) {
                    textOpacity = 1
                }

                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isVisible = false
                    }
                    try? await Task.sleep(nanoseconds: 400_000_000)
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
