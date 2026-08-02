import SwiftUI

struct MeditationHistoryView: View {
    let sessions: [MeditationSession]
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(Typography.iconButton)
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)

                Text(L10n.MeditationHistory.title)
                    .font(Typography.sectionTitle)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(sessions) { session in
                            MeditationSessionRow(session: session)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.background)
    }

    private var emptyState: some View {
        Text(L10n.MeditationHistory.emptyStateTitle)
            .font(Theme.uiFont)
            .foregroundStyle(Theme.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension L10n {
    enum MeditationHistory {
        static var title: String {
            switch lang {
            case .en: return "history"
            case .pl: return "historia"
            }
        }

        static var emptyStateTitle: String {
            switch lang {
            case .en: return "No sessions yet"
            case .pl: return "Brak sesji"
            }
        }

        static var noIntention: String {
            switch lang {
            case .en: return "(no intention)"
            case .pl: return "(brak intencji)"
            }
        }
    }
}
