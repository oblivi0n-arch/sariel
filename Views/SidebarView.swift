import SwiftUI

struct SidebarView: View {
    @State private var selectedSection: AppSection = .chat

    var body: some View {
        VStack(spacing: 16) {
            ForEach(AppSection.allCases) { section in
                sidebarIcon(for: section)
            }

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

    private func sidebarIcon(for section: AppSection) -> some View {
        let isActive = section == selectedSection

        return Image(systemName: section.iconName)
            .font(.system(size: 18))
            .foregroundStyle(isActive ? Theme.accentBright : Theme.textFaint)
            .frame(width: 36, height: 36)
            .background(isActive ? Theme.accent : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                selectedSection = section
            }
    }
}

#Preview {
    SidebarView()
        .frame(height: 500)
        .background(Theme.background)
}
