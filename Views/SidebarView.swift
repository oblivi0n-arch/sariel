import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var connectionMonitor: ConnectionMonitor
    @State private var selectedSection: AppSection = .chat

    var body: some View {
        VStack(spacing: 16) {
            statusDot

            ForEach(AppSection.allCases) { section in
                sidebarIcon(for: section)
            }

            Spacer()
        }
        .padding(.top, 20)
        .frame(width: 56)
        .frame(maxHeight: .infinity)
        .background(Theme.background)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Theme.border)
                .frame(width: 0.5)
        }
    }

    private var statusDot: some View {
        Group {
            if connectionMonitor.isConnected {
                Circle().fill(Theme.textPrimary)
            } else {
                Circle().stroke(Theme.textFaint, lineWidth: 1)
            }
        }
        .frame(width: 8, height: 8)
    }

    private func sidebarIcon(for section: AppSection) -> some View {
        let isActive = section == selectedSection

        return Image(systemName: section.iconName)
            .font(.system(size: 18))
            .foregroundStyle(isActive ? Theme.textPrimary : Theme.textFaint)
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? Theme.borderStrong : .clear, lineWidth: 1)
            )
            .onTapGesture {
                selectedSection = section
            }
    }
}

#Preview {
    SidebarView()
        .frame(height: 500)
        .background(Theme.background)
        .environmentObject(ConnectionMonitor())
}
