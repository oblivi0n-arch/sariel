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
        .background(Theme.surface)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Theme.border)
                .frame(width: 0.5)
        }
    }
    
    private var statusDot: some View {
        Circle()
            .fill(connectionMonitor.isConnected ? Color.green : Color.red)
            .frame(width: 8, height: 8)
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
        .environmentObject(ConnectionMonitor())
}
