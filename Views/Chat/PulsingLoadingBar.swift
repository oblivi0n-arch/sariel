import SwiftUI

struct PulsingLoadingBar: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let chunkWidth = geo.size.width * 0.3
            let travelDistance = geo.size.width + chunkWidth

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.fieldBackground)

                Rectangle()
                    .fill(Theme.textPrimary)
                    .frame(width: chunkWidth)
                    .offset(x: -chunkWidth + progress * travelDistance)
            }
        }
        .frame(height: 3)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                progress = 1
            }
        }
    }
}
