import SwiftUI

struct DashboardView: View {
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            Text("COMING SOON")
                .font(Typography.sectionTitle)
                .foregroundStyle(Theme.textFaint)
                .tracking(4)
        }
    }
}
