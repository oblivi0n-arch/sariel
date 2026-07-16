import SwiftUI

struct EndConversationLoadingBar: View {
    @State private var progress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.background)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geo.size.width * self.progress)
            }
        }
        .frame(height: 3)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                progress = 1
            }
        }
    }
}
