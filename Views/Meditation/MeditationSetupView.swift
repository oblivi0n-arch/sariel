import SwiftUI

struct MeditationSetupView: View {
    let sessions: [MeditationSession]
    let onStart: (String, MeditationDuration) -> Void
    let onDelete: (MeditationSession) -> Void
    
    @State private var intention: String = ""
    @State private var selectedDuration: MeditationDuration = .tenMinutes
    @State private var isHistoryExpanded = false
    @State private var isHoveringHistory = false
    @State private var isInfoShown = false
    @State private var isHoveringInfo = false
    @FocusState private var isIntentionFocused: Bool
    
    @ObservedObject private var languageManager = LanguageManager.shared
    @AppStorage("meditationPlaceholderIndex") private var placeholderIndex: Int = 0
    @AppStorage("meditationPlaceholderDate") private var placeholderDateString: String = ""
    @State private var intentionPlaceholderText: String = ""
    
    var body: some View {
        ZStack {
            AmbientRingsView()
            
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { isInfoShown = true }) {
                        Image(systemName: "info.circle")
                            .font(Typography.iconButton)
                            .foregroundStyle(isHoveringInfo ? Theme.textPrimary : Theme.textMuted)
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isHoveringInfo ? Theme.border : .clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .trackHover($isHoveringInfo)
                    
                    Button(action: toggleHistory) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(Typography.iconButton)
                            .foregroundStyle(isHistoryExpanded ? Theme.textPrimary : Theme.textMuted)
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isHoveringHistory ? Theme.border : .clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .trackHover($isHoveringHistory)
                }
                .padding(20)
                
                if isHistoryExpanded {
                    historyPanel
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 0) {
                    Text(L10n.MeditationSetup.intentionLabel)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                        .textCase(.uppercase)
                        .kerning(0.5)
                        .multilineTextAlignment(.center)
                    
                    PlaceholderTextField(
                        placeholder: intentionPlaceholderText,
                        text: $intention,
                        font: Typography.title,
                        textColor: Theme.textPrimary,
                        textAlignment: .center
                    )
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .focused($isIntentionFocused)
                    
                    Text(L10n.MeditationSetup.durationLabel)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                        .textCase(.uppercase)
                        .kerning(0.5)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        ForEach(MeditationDuration.allCases, id: \.self) { duration in
                            DurationOptionView(
                                duration: duration,
                                isSelected: selectedDuration == duration,
                                onTap: { selectedDuration = duration }
                            )
                        }
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: 480)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: startSession) {
                        Text(L10n.MeditationSetup.startButton)
                            .font(Typography.label)
                            .foregroundStyle(Theme.background)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .hoverScale()
                }
                .padding(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .overlay {
            if isInfoShown {
                infoOverlay
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isInfoShown)
        .onAppear {
            isIntentionFocused = true
            updatePlaceholderIfNeeded()
        }
        .onChange(of: languageManager.current) { _, _ in
            updatePlaceholderIfNeeded()
        }
    }
    
    private var historyPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.MeditationHistory.title)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
                .textCase(.uppercase)
                .kerning(0.5)
            
            if sessions.isEmpty {
                Text(L10n.MeditationHistory.emptyStateTitle)
                    .font(Typography.label)
                    .foregroundStyle(Theme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(sessions) { session in
                            MeditationSessionRow(session: session, onDelete: { onDelete(session) })
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
        }
        .padding(16)
        .background(Theme.background)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.borderStrong, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
            .frame(maxWidth: 420, maxHeight: 420)
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
            Image(systemName: "circle.dotted")
                .font(Typography.icon)
                .foregroundStyle(Theme.textMuted)

            Text(L10n.MeditationSetup.infoTitle)
                .font(Typography.title)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Button(action: { isInfoShown = false }) {
                Image(systemName: "xmark")
                    .font(Typography.iconButton)
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                    .hoverBorder(Circle())
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
            ForEach(Array(L10n.MeditationSetup.steps.enumerated()), id: \.offset) { index, step in
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
    
    private func toggleHistory() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isHistoryExpanded.toggle()
        }
    }
    
    private func startSession() {
        onStart(intention.trimmingCharacters(in: .whitespacesAndNewlines), selectedDuration)
    }
    
    private func updatePlaceholderIfNeeded() {
        let todayString = Date().dayKey
        let placeholders = L10n.MeditationSetup.intentionPlaceholders

        if placeholderDateString != todayString {
            placeholderIndex = placeholders.indices.randomElement() ?? 0
            placeholderDateString = todayString
        }

        let safeIndex = min(placeholderIndex, placeholders.count - 1)
        intentionPlaceholderText = placeholders[safeIndex]
    }
}

private struct DurationOptionView: View {
    let duration: MeditationDuration
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(duration.displayName)
            .font(Typography.label)
            .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Theme.borderStrong : Theme.border, lineWidth: 0.5))
            .hoverBorder(cornerRadius: 8)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
    }
}

extension L10n {
    enum MeditationSetup {
        static var intentionLabel: String {
            switch lang {
            case .en: return "INTENTION"
            case .pl: return "INTENCJA"
            }
        }
        
        static var intentionPlaceholders: [String] {
            switch lang {
            case .en:
                return [
                    "What are you avoiding right now?",
                    "What are you putting off so you don't have to think about it?",
                    "What truth are you making easier for yourself today?",
                    "What do you know but pretend you don't?",
                    "What are you lying to yourself about right now?"
                ]
            case .pl:
                return [
                    "Czego teraz unikasz?",
                    "Co odkładasz, żeby o tym nie myśleć?",
                    "Jaką prawdę sobie dziś ułatwiasz?",
                    "Co wiesz, ale udajesz, że nie wiesz?",
                    "Nad czym się teraz oszukujesz?"
                ]
            }
        }
        
        static var durationLabel: String {
            switch lang {
            case .en: return "DURATION"
            case .pl: return "CZAS"
            }
        }
        
        static var startButton: String {
            switch lang {
            case .en: return "Sit with it"
            case .pl: return "Usiądź z tym"
            }
        }
        
        static var infoTitle: String {
            switch lang {
            case .en: return "meditation"
            case .pl: return "medytacja"
            }
        }

        static var steps: [String] {
            switch lang {
            case .en:
                return [
                    "Set an intention — what you're avoiding today — and pick a session length.",
                    "During the session you can extend it by 5 minutes, pause it, or end it early.",
                    "Each session is saved to your history along with its duration and whether it was interrupted.",
                    "It's a pause between confrontations, not an escape from them."
                ]
            case .pl:
                return [
                    "Podaj intencję — czego dziś unikasz — i wybierz długość sesji.",
                    "W trakcie możesz przedłużyć sesję o 5 minut, wstrzymać ją lub zakończyć wcześniej.",
                    "Sesja zapisuje się w historii razem z czasem trwania i informacją, czy została przerwana.",
                    "To pauza między konfrontacjami, nie ucieczka od nich."
                ]
            }
        }
    }
    
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
            case .en: return "no intention set"
            case .pl: return "bez intencji"
            }
        }
        
        static var delete: String {
            switch lang {
            case .en: return "Delete"
            case .pl: return "Usuń"
            }
        }
    }
}
