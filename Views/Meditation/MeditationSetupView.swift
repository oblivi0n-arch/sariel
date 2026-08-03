import SwiftUI

struct MeditationSetupView: View {
    let sessions: [MeditationSession]
    let onStart: (String, MeditationDuration) -> Void
    
    @State private var intention: String = ""
    @State private var selectedDuration: MeditationDuration = .tenMinutes
    @State private var isHistoryExpanded = false
    @State private var isHoveringHistory = false
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
                    Button(action: toggleHistory) {
                        Image(systemName: "clock.arrow.circlepath")
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
                            MeditationSessionRow(session: session)
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
            case .en: return "(no intention)"
            case .pl: return "(brak intencji)"
            }
        }
    }
}
