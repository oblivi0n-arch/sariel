import SwiftUI

struct MeditationCompletionView: View {
    let session: MeditationSession
    let onDismiss: () -> Void
    
    @State private var areStatsVisible = false

    private var durationText: String {
        let plannedMinutes = Int(session.plannedDuration / 60)
        let actualMinutes = Int((session.actualDuration / 60).rounded())
        return session.wasInterrupted ? "\(actualMinutes)/\(plannedMinutes) min" : "\(plannedMinutes) min"
    }

    private var statusText: String {
        session.wasInterrupted ? L10n.MeditationCompletion.interrupted : L10n.MeditationCompletion.completed
    }

    private var reflectionText: String {
        session.wasInterrupted ? L10n.MeditationCompletion.interruptedReflection : L10n.MeditationCompletion.completedReflection
    }

    var body: some View {
        ZStack {
            AmbientRingsView()

            VStack(spacing: 24) {
                Spacer()

                RevealingText(
                    fullText: reflectionText,
                    font: Typography.title,
                    color: Theme.textPrimary,
                    onComplete: {
                        withAnimation(.easeOut(duration: 0.5)) {
                            areStatsVisible = true
                        }
                    }
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

                HStack(spacing: 12) {
                    DashboardStatCard(label: L10n.MeditationCompletion.durationLabel, value: durationText)
                    DashboardStatCard(label: L10n.MeditationCompletion.statusLabel, value: statusText)
                }
                .frame(maxWidth: 360)
                .opacity(areStatsVisible ? 1 : 0)
                .offset(y: areStatsVisible ? 0 : 12)

                Spacer()

                Button(action: onDismiss) {
                    Text(L10n.MeditationCompletion.returnButton)
                        .font(Typography.label)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .hoverBorder(cornerRadius: 8)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
}

extension L10n {
    enum MeditationCompletion {
        static var durationLabel: String {
            switch lang {
            case .en: return "duration"
            case .pl: return "czas"
            }
        }

        static var statusLabel: String {
            switch lang {
            case .en: return "status"
            case .pl: return "status"
            }
        }

        static var completed: String {
            switch lang {
            case .en: return "full session"
            case .pl: return "pełna sesja"
            }
        }

        static var interrupted: String {
            switch lang {
            case .en: return "interrupted"
            case .pl: return "przerwana"
            }
        }

        static var completedReflection: String {
            switch lang {
            case .en: return "You stayed for the full planned time."
            case .pl: return "Dotrwałeś do końca zaplanowanego czasu."
            }
        }

        static var interruptedReflection: String {
            switch lang {
            case .en: return "You ended earlier than planned."
            case .pl: return "Skończyłeś wcześniej niż planowałeś."
            }
        }

        static var returnButton: String {
            switch lang {
            case .en: return "back"
            case .pl: return "wróć"
            }
        }
    }
}
