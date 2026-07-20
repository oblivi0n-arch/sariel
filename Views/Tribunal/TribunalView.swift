import SwiftUI
import SwiftData

struct TribunalView: View {
    @ObservedObject var chatService: ChatService
    let onTribunalStarted: (Conversation) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var isStarting = false
    @State private var isHistoryExpanded = false

    @Query(filter: #Predicate<Commitment> { $0.status == "pending" }, sort: \Commitment.createdAt)
    private var pendingCommitments: [Commitment]
    @Query(
        filter: #Predicate<Commitment> { $0.status != "pending" },
        sort: \Commitment.resolvedAt,
        order: .reverse
    )
    private var resolvedCommitments: [Commitment]

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
    
    private let tribunalSteps = [
        "A message starting with \"I declare\" becomes a commitment.",
        "Seven days pass from the oldest unresolved commitment.",
        "The Tribunal unlocks — it cannot be rushed or skipped.",
        "You face it and account for what you promised. Nothing is self-approved outside the Tribunal."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tribunal")
                .font(Typography.sectionTitle)
                .foregroundStyle(Theme.textPrimary)
                .padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    explanation
                    statusSection

                    if !resolvedCommitments.isEmpty {
                        historySection
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.background)
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HOW IT WORKS")
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
                .kerning(0.5)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(tribunalSteps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(Typography.label)
                            .foregroundStyle(Theme.textFaint)
                            .frame(width: 16, alignment: .leading)

                        Text(step)
                            .font(Theme.uiFont)
                            .foregroundStyle(Theme.textSecondary)
                            .lineSpacing(3)
                    }
                }
            }
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
        Button(action: startTribunal) {
            Text(isStarting ? "Opening..." : "Face the Tribunal")
                .font(Typography.label)
                .foregroundStyle(Theme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Theme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isStarting)
        .opacity(isStarting ? 0.6 : 1)
    }

    private func startTribunal() {
        guard !isStarting else { return }
        isStarting = true
        Task {
            if let conversation = await chatService.startTribunal(modelContext: modelContext) {
                onTribunalStarted(conversation)
            }
            isStarting = false
        }
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
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: toggleHistory) {
                HStack(spacing: 6) {
                    Text("HISTORY")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                        .kerning(0.5)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Theme.textFaint)
                        .rotationEffect(.degrees(isHistoryExpanded ? 90 : 0))
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if isHistoryExpanded {
                VStack(spacing: 8) {
                    ForEach(resolvedCommitments) { commitment in
                        CommitmentHistoryRow(commitment: commitment)
                    }
                }
            }
        }
    }

    private func toggleHistory() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isHistoryExpanded.toggle()
        }
    }
}
