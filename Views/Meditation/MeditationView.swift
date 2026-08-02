import SwiftUI

struct MeditationView: View {
    var body: some View {
        VStack {
            Spacer()
            Text(L10n.Meditation.placeholderTitle)
                .font(Typography.title)
                .foregroundStyle(Theme.textFaint)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
}

extension L10n {
    enum Meditation {
        static var placeholderTitle: String {
            switch lang {
            case .en: return "Meditation — coming soon"
            case .pl: return "Medytacja — wkrótce"
            }
        }
    }
}
