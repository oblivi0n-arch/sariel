import SwiftUI
import SwiftData

struct TribunalView: View {
    @Query(filter: #Predicate<Commitment> { $0.status == "pending" }, sort: \Commitment.createdAt)
    private var pendingCommitments: [Commitment]

    private let unlockInterval: TimeInterval = 7 * 24 * 60 * 60

    private var oldestPendingDate: Date? {
        pendingCommitments.first?.createdAt
    }

    private var isUnlocked: Bool {
        guard let oldest = oldestPendingDate else { return false }
        return Date().timeIntervalSince(oldest) >= unlockInterval
    }

    private var daysRemaining: Int? {
        guard let oldest = oldestPendingDate, !isUnlocked else { return nil }
        let remaining = unlockInterval - Date().timeIntervalSince(oldest)
        return max(0, Int(ceil(remaining / (24 * 60 * 60))))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Tribunal")
                .font(Typography.sectionTitle)
                .foregroundStyle(Theme.textPrimary)

            explanation
            statusSection

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.background)
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HOW IT WORKS")
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
                .kerning(0.5)

            Text("A message starting with \"I declare\" becomes a commitment. Seven days after the oldest unresolved commitment, the Tribunal unlocks — you must face it and account for what you promised. Nothing can be self-approved outside the Tribunal.")
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
        }
        .padding(14)
        .background(Theme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if pendingCommitments.isEmpty {
                statusPill(icon: "checkmark.circle", text: "No pending commitments")
            } else if isUnlocked {
                statusPill(
                    icon: "lock.open.fill",
                    text: "\(pendingCommitments.count) commitments awaiting trial",
                    color: Theme.textPrimary
                )
                startButton
            } else if let days = daysRemaining {
                statusPill(icon: "lock.fill", text: "Locked — \(days) days left")
            }
        }
    }

    private var startButton: some View {
        Button(action: {
            // TODO: launch the actual Tribunal conversation (next step)
        }) {
            Text("Face the Tribunal")
                .font(Typography.label)
                .foregroundStyle(Theme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Theme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func statusPill(icon: String, text: String, color: Color = Theme.textSecondary) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(text)
                .font(Typography.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.fieldBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
    }
}
