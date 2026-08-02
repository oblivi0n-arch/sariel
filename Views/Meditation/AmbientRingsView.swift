import SwiftUI

struct AmbientRingsView: View {
    var radii: [CGFloat] = [90, 150, 210]
    var opacity: Double = 0.05
    var lineWidth: CGFloat = 1

    var body: some View {
        ZStack {
            ForEach(radii, id: \.self) { radius in
                Circle()
                    .stroke(Theme.textPrimary.opacity(opacity), lineWidth: lineWidth)
                    .frame(width: radius * 2, height: radius * 2)
            }
        }
        .allowsHitTesting(false)
    }
}
