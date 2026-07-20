import SwiftUI
import SwiftData

struct TribunalView: View {
    @ObservedObject var chatService: ChatService
    let onTribunalStarted: (Conversation) -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var isStarting = false
    @State private var isHistoryExpanded = false
    @State private var isInfoShown = false
    
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
        "In any conversation, type a message starting with \"I declare\" — it's saved as a commitment.",
        "Seven days pass from the oldest unresolved commitment.",
        "The Tribunal unlocks — it cannot be rushed or skipped.",
        "You face it and account for what you promised. Nothing is self-approved outside the Tribunal."
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("Tribunal")
                    .font(Typography.sectionTitle)
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                Button(action: { isInfoShown = true }) {
                    Image(systemName: "info.circle")
                        .font(Typography.icon)
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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
        .overlay {
            if isInfoShown {
                infoOverlay
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isInfoShown)
    }
    
    private var infoOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { isInfoShown = false }
            
            VStack(alignment: .leading, spacing: 0) {
                infoHeader
                
                ScrollView {
                    explanationSteps
                        .padding(20)
                }
            }
            .frame(maxWidth: 420, maxHeight: 480)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.6), radius: 40, y: 12)
            .onTapGesture {}
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
    
    private var infoHeader: some View {
        HStack {
            Image(systemName: "seal")
                .font(Typography.icon)
                .foregroundStyle(Theme.textMuted)
            
            Text("tribunal")
                .font(Typography.title)
                .foregroundStyle(Theme.textPrimary)
            
            Spacer()
            
            Button(action: { isInfoShown = false }) {
                Image(systemName: "xmark")
                    .font(Typography.iconButton)
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 24, height: 24)
                    .background(Theme.fieldBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.border).frame(height: 0.5)
        }
    }
    
    private var explanationSteps: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(tribunalSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(Typography.subsectionTitle)
                        .foregroundStyle(Theme.textFaint)
                        .frame(width: 20, alignment: .leading)
                    
                    Text(step)
                        .font(Theme.uiFont)
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(3)
                }
            }
        }
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
