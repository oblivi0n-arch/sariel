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
    @State private var emptyStateText: String = L10n.Tribunal.emptyStateTexts.randomElement()!
    
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
    
    var body: some View {
        Group {
            if let conversation = activeTribunalConversation {
                ChatView(
                    conversation: conversation,
                    chatService: chatService,
                    isConversationListOpen: .constant(false),
                    onJournalEntryCreated: { _ in },
                    onDeclarationLimitBlocked: {},
                    onDeclarationEditBlocked: {},
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
        CredibilityBand.percentage(from: resolvedCommitments)
    }

    private var credibilityBand: CredibilityBand {
        CredibilityBand.evaluate(from: resolvedCommitments)
    }

    private var credibilitySection: some View {
        HStack(spacing: 10) {
            Image(systemName: "scalemass")
                .font(.system(size: 20))
                .foregroundStyle(Theme.textMuted)

            if let percentage = credibilityPercentage {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Tribunal.credibilityPercentage(Int(percentage.rounded())))
                        .font(Theme.uiFont)
                        .foregroundStyle(Theme.textPrimary)

                    Text(credibilityBand.displayName.uppercased())
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                        .kerning(0.5)
                }
            } else {
                Text(L10n.Tribunal.credibilityInsufficient)
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
                Text(L10n.Tribunal.title)
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
            
            Text(L10n.Tribunal.infoTitle)
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
            ForEach(Array(L10n.Tribunal.steps.enumerated()), id: \.offset) { index, step in
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

            Text(L10n.Tribunal.commitmentsAwaitTrial(count: pendingCommitments.count))
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
            Text(isStarting ? L10n.Tribunal.opening : L10n.Tribunal.faceTheTribunal)
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
                    Text(L10n.Tribunal.historyLabel)
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

            Text(L10n.Tribunal.countdownLabel)
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

extension L10n {
    enum Tribunal {
        static var title: String {
            switch lang {
            case .en: return "Tribunal"
            case .pl: return "Trybunał"
            }
        }

        static var infoTitle: String {
            switch lang {
            case .en: return "tribunal"
            case .pl: return "trybunał"
            }
        }

        static func credibilityPercentage(_ value: Int) -> String {
            switch lang {
            case .en: return "\(value)% credibility"
            case .pl: return "\(value)% wiarygodności"
            }
        }

        static var credibilityInsufficient: String {
            switch lang {
            case .en: return "Not enough resolved declarations yet to judge your credibility."
            case .pl: return "Za mało rozstrzygniętych deklaracji, by ocenić Twoją wiarygodność."
            }
        }

        static var opening: String {
            switch lang {
            case .en: return "Opening..."
            case .pl: return "Otwieranie..."
            }
        }

        static var faceTheTribunal: String {
            switch lang {
            case .en: return "Face the Tribunal"
            case .pl: return "Stań przed Trybunałem"
            }
        }

        static var historyLabel: String {
            switch lang {
            case .en: return "HISTORY"
            case .pl: return "HISTORIA"
            }
        }

        static var countdownLabel: String {
            switch lang {
            case .en: return "days : hours : minutes"
            case .pl: return "dni : godziny : minuty"
            }
        }

        static func commitmentsAwaitTrial(count: Int) -> String {
            switch lang {
            case .en:
                return "\(count) commitment\(count == 1 ? "" : "s") await\(count == 1 ? "s" : "") trial"
            case .pl:
                let lastDigit = count % 10
                let lastTwoDigits = count % 100
                let noun: String
                let verb: String
                if count == 1 {
                    noun = "zobowiązanie"; verb = "czeka"
                } else if (2...4).contains(lastDigit) && !(12...14).contains(lastTwoDigits) {
                    noun = "zobowiązania"; verb = "czekają"
                } else {
                    noun = "zobowiązań"; verb = "czeka"
                }
                return "\(count) \(noun) \(verb) na proces"
            }
        }

        static var steps: [String] {
            switch lang {
            case .en:
                return [
                    "In any conversation, type a message starting with \"I declare\" — it's saved as a commitment.",
                    "A declaration is permanent. It cannot be edited, deleted, or rewound once sent.",
                    "Three days pass from the oldest unresolved commitment.",
                    "The Tribunal unlocks — it cannot be rushed or skipped.",
                    "You face it and account for what you promised. Nothing is self-approved outside the Tribunal."
                ]
            case .pl:
                return [
                    "W dowolnej rozmowie napisz wiadomość zaczynającą się od \"ja deklaruję\" — zostanie zapisana jako zobowiązanie.",
                    "Deklaracja jest trwała. Po wysłaniu nie można jej edytować, usunąć ani cofnąć.",
                    "Mijają trzy dni od najstarszego nierozstrzygniętego zobowiązania.",
                    "Trybunał się odblokowuje — nie da się tego przyspieszyć ani pominąć.",
                    "Stajesz przed nim i rozliczasz się z tego, co obiecałeś. Nic nie jest zatwierdzane samemu poza Trybunałem."
                ]
            }
        }

        static var emptyStateTexts: [String] {
            switch lang {
            case .en:
                return [
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
            case .pl:
                return [
                    "Nic nie czeka na osąd. Na razie masz czyste sumienie.",
                    "Brak zobowiązań w toku. Niech tak zostanie, albo nie — ale wiedz, co właśnie wybierasz.",
                    "Trybunał nie ma za co Cię sądzić. Na razie.",
                    "Cisza tutaj to nie spokój. To po prostu brak obietnic.",
                    "Niczego nie zadeklarowałeś, więc nie masz czego złamać. To nie to samo, co dotrzymywanie słowa.",
                    "Pusto, bo się nie sprawdziłeś. To też warto zauważyć.",
                    "Brak wyroków w toku. Ale też brak jakiegokolwiek dowodu na cokolwiek.",
                    "Nie masz się teraz z czego rozliczyć. Nie myl tego z postępem.",
                    "Rejestr jest czysty. Nie zostanie taki, jeśli naprawdę myślisz to, co mówisz.",
                    "Nikt dziś na Ciebie nie czeka z wyrokiem. To był Twój wybór, nie przypadek."
                ]
            }
        }
    }
}
