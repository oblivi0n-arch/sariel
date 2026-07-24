import SwiftUI

struct DashboardView: View {
    @AppStorage("username") private var username: String = ""
    @AppStorage("dashboardGreetingIndex") private var greetingIndex: Int = 0
    @AppStorage("dashboardGreetingDate") private var greetingDateString: String = ""

    @State private var greetingText: String = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                RevealingText(
                    fullText: greetingText,
                    font: .system(size: 26, weight: .medium, design: .serif),
                    color: Theme.textPrimary
                )
                .id(greetingText)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    DashboardStatCard(label: L10n.Dashboard.lastActivityLabel, value: "3 godz. temu")
                    DashboardStatCard(label: L10n.Dashboard.streakLabel, value: "7 dni")
                    DashboardStatCard(label: L10n.Dashboard.journalEntriesLabel, value: "24")
                }
                Spacer()
            }
            .padding(28)
        }
        .onAppear {
            updateGreetingIfNeeded()
        }
    }

    private func updateGreetingIfNeeded() {
        let todayString = Self.dayFormatter.string(from: Date())

        if greetingDateString != todayString {
            greetingIndex = L10n.Dashboard.greetings.indices.randomElement() ?? 0
            greetingDateString = todayString
        }

        let name = username.isEmpty ? L10n.Dashboard.fallbackName : username
        greetingText = L10n.Dashboard.greetings[greetingIndex]
            .replacingOccurrences(of: "{name}", with: name)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

extension L10n {
    enum Dashboard {
        static var greetings: [String] {
            switch lang {
            case .pl:
                return [
                    "Znowu tu jesteś, {name}. Zobaczmy, co dziś naprawdę myślisz.",
                    "{name}, usiądź na chwilę. Czas przyjrzeć się dzisiejszym myślom.",
                    "Kolejny dzień, kolejna szansa na szczerość, {name}.",
                    "Witaj, {name}. Zaczynajmy — bez zbędnych wstępów.",
                    "{name}, lustro czeka. Co dziś w nim zobaczysz?",
                    "Wróciłeś, {name}. Dobrze. Bądźmy dziś szczerzy."
                ]
            case .en:
                return [
                    "Back again, {name}. Let's see what you're really thinking today.",
                    "{name}, take a seat. Time to look at today's thoughts.",
                    "Another day, another chance at honesty, {name}.",
                    "Welcome, {name}. Let's get into it.",
                    "{name}, the mirror's waiting. What will you see today?",
                    "You're back, {name}. Good. Let's be honest today."
                ]
            }
        }

        static var fallbackName: String {
            switch lang {
            case .pl: return "nieznajomy"
            case .en: return "stranger"
            }
        }
        
        static var lastActivityLabel: String {
            switch lang {
            case .pl: return "OSTATNIA AKTYWNOŚĆ"
            case .en: return "LAST ACTIVITY"
            }
        }

        static var streakLabel: String {
            switch lang {
            case .pl: return "PASSA"
            case .en: return "STREAK"
            }
        }

        static var journalEntriesLabel: String {
            switch lang {
            case .pl: return "WPISY W DZIENNIKU"
            case .en: return "JOURNAL ENTRIES"
            }
        }
    }
}
