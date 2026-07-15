import SwiftUI

struct SidebarView: View {
    var body: some View {
        VStack(spacing: 16) {
            sidebarIcon(systemName: "bubble.left.and.bubble.right.fill", isActive: true)

            Spacer()
        }
        .padding(.top, 20)
        .frame(width: 56)
        .frame(maxHeight: .infinity)
        .background(Theme.surface)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Theme.border)
                .frame(width: 0.5)
        }
    }

    private func sidebarIcon(systemName: String, isActive: Bool) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 18))
            .foregroundStyle(isActive ? Theme.accentBright : Theme.textFaint)
            .frame(width: 36, height: 36)
            .background(isActive ? Theme.accent : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    SidebarView()
        .frame(height: 500)
        .background(Theme.background)
}
