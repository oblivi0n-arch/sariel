import SwiftUI

struct MeditationSessionRow: View {
    let session: MeditationSession

    private var durationText: String {
        let plannedMinutes = Int(session.plannedDuration / 60)
        let actualMinutes = Int((session.actualDuration / 60).rounded())
        return session.wasInterrupted ? "\(actualMinutes)/\(plannedMinutes) min" : "\(plannedMinutes) min"
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(session.intention.isEmpty ? L10n.MeditationHistory.noIntention : session.intention)
                .font(Typography.title)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)

            Spacer()

            Text(durationText)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)

            Text(session.createdAt, style: .date)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.borderStrong, lineWidth: 1))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Theme.textPrimary.opacity(session.wasInterrupted ? 0.3 : 1.0))
                .frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
