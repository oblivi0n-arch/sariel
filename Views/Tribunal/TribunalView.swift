import SwiftUI
import SwiftData

struct TribunalView: View {
    @ObservedObject var chatService: ChatService
    
    @Environment(\.modelContext) private var modelContext
    @State private var isStarting = false
    @State private var isHistoryExpanded = false
    @State private var isInfoShown = false
    @State private var now: Date = Date()
    @State private var tickTask: Task<Void, Never>?
    @State private var activeTribunalConversation: Conversation?
    @State private var emptyStateText: String = TribunalView.emptyStateTexts.randomElement()!
    
    @Query(filter: #Predicate<Commitment> { $0.status == "pending" }, sort: \Commitment.createdAt)
    private var pendingCommitments: [Commitment]
    @Query(
        filter: #Predicate<Commitment> { $0.status != "pending" },
        sort: \Commitment.resolvedAt,
        order: .reverse
    )
    private var resolvedCommitments: [Commitment]
    
    private var oldestPendingDate: Date? {
        pendingCommitments.first?.createdAt
    }
    
    private var isUnlocked: Bool {
        guard let oldest = oldestPendingDate else { return false }
        return now.timeIntervalSince(oldest) >= Commitment.tribunalUnlockInterval
    }
    
    private var remainingComponents: (days: Int, hours: Int, minutes: Int)? {
        guard let oldest = oldestPendingDate, !isUnlocked else { return nil }
        let remaining = max(0, Commitment.tribunalUnlockInterval - now.timeIntervalSince(oldest))
        let totalMinutes = Int(remaining) / 60
        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes % (24 * 60)) / 60
        let minutes = totalMinutes % 60
        return (days, hours, minutes)
    }
    
    private let tribunalSteps = [
        "In any conversation, type a message starting with \"I declare\" — it's saved as a commitment.",
        "A declaration is permanent. It cannot be edited, deleted, or rewound once sent.",
        "Seven days pass from the oldest unresolved commitment.",
        "The Tribunal unlocks — it cannot be rushed or skipped.",
        "You face it and account for what you promised. Nothing is self-approved outside the Tribunal."
    ]
    
    private static let emptyStateTexts = [
        "Nothing awaits judgment. For now, your word is clean.",
        "No pending commitments. Keep it that way, or don't — but know which one you're choosing.",
        "The Tribunal has nothing to try you for. Yet.",
        "Silence here isn't peace. It's just an absence of promises.",
        "You haven't declared anything you could break. That's not the same as keeping your word.",
        "Empty, because you haven't tested yourself. That's worth noticing too.",
        "No verdicts pending. No proof of anything, either.",
        "Nothing to answer for right now. Don't mistake that for progress.",
        "The docket is clear. It won't stay that way if you mean anything you say.",
        "No one is waiting to judge you today. That was your choice, not an accident."
    ]
    
    var body: some View {
        Group {
            if let conversation = activeTribunalConversation {
                ChatView(
                    conversation: conversation,
                    chatService: chatService,
                    isConversationListOpen: .constant(false),
                    onJournalEntryCreated: { _ in },
                    onDeclarationLimitBlocked: {},
                    onOpenJournalEntry: { _ in },
                    onBackToTribunal: { activeTribunalConversation = nil },
                    isActive: true
                )
            } else {
                mainTribunalContent
            }
        }
        .onAppear {
            restoreInProgressTribunalIfNeeded()
        }
    }
    
    private var credibilityPercentage: Double? {
        Commitment.credibilityPercentage(from: resolvedCommitments)
    }

    private var credibilityBand: CredibilityBand {
        Commitment.credibilityBand(from: resolvedCommitments)
    }

    private var credibilitySection: some View {
        HStack(spacing: 10) {
            Image(systemName: "scalemass")
                .font(.system(size: 20))
                .foregroundStyle(Theme.textMuted)

            if let percentage = credibilityPercentage {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(percentage.rounded()))% credibility")
                        .font(Theme.uiFont)
                        .foregroundStyle(Theme.textPrimary)

                    Text(credibilityBand.rawValue.uppercased())
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                        .kerning(0.5)
                }
            } else {
                Text("Not enough resolved declarations yet to judge your credibility.")
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
    }
    
    private var mainTribunalContent: some View {
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
                    credibilitySection
                    
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
        .onAppear { startTicking() }
        .onDisappear { tickTask?.cancel() }
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
                noCommitmentsView
            } else if isUnlocked {
                unlockedView
                startButton
            } else if let components = remainingComponents {
                countdownView(components)
            }
        }
    }
    
    private var noCommitmentsView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 20))
                .foregroundStyle(Theme.textPrimary)

            Text(emptyStateText)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.borderStrong, lineWidth: 0.5))
    }

    private var unlockedView: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.red.opacity(0.85))

            Text("\(pendingCommitments.count) commitment\(pendingCommitments.count == 1 ? "" : "s") await\(pendingCommitments.count == 1 ? "s" : "") trial")
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.4), lineWidth: 0.5))
    }
    
    private var startButton: some View {
        Button(action: startTribunal) {
            Text(isStarting ? "Opening..." : "Face the Tribunal")
                .font(Typography.label)
                .foregroundStyle(Color.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.4), lineWidth: 0.5))
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
                activeTribunalConversation = conversation
            }
            isStarting = false
        }
    }
    
    private func restoreInProgressTribunalIfNeeded() {
        guard activeTribunalConversation == nil else { return }
        activeTribunalConversation = chatService.fetchInProgressTribunal(modelContext: modelContext)
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
                        CommitmentHistoryRow(commitment: commitment, onSelect: {
                            if let conversation = commitment.resolvingConversation {
                                activeTribunalConversation = conversation
                            }
                        })
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
    
    private func countdownView(_ components: (days: Int, hours: Int, minutes: Int)) -> some View {
        VStack(spacing: 6) {
            Text(String(format: "%02d:%02d:%02d", components.days, components.hours, components.minutes))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)

            Text("days : hours : minutes")
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
                .kerning(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.borderStrong, lineWidth: 0.5))
    }
    
    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task {
            while !Task.isCancelled {
                now = Date()
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30s
            }
        }
    }
}
