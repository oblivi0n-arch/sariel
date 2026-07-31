import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("username") private var username: String = ""
    @AppStorage("dashboardGreetingIndex") private var greetingIndex: Int = 0
    @AppStorage("dashboardGreetingDate") private var greetingDateString: String = ""
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Query(sort: \JournalEntry.createdAt, order: .reverse)
    private var journalEntries: [JournalEntry]
    @State private var greetingText: String = ""
    let toastManager: ToastManager
    let achievementService: AchievementService
    @Query private var achievementUnlocks: [AchievementUnlock]
    @State private var selectedUnlock: AchievementUnlock?
    @State private var isAchievementsScreenShown = false
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(journalEntries.map { calendar.startOfDay(for: $0.createdAt) })
        guard !uniqueDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var dayToCheck = uniqueDays.contains(today) ? today : yesterday
        guard uniqueDays.contains(dayToCheck) else { return 0 }

        var streak = 0
        while uniqueDays.contains(dayToCheck) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: dayToCheck) else { break }
            dayToCheck = previousDay
        }
        return streak
    }
    
    private var lastActivityText: String {
        guard let mostRecent = journalEntries.first?.createdAt else {
            return L10n.Dashboard.noActivityYet
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: L10n.lang == .pl ? "pl_PL" : "en_US")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: mostRecent, relativeTo: Date())
    }
    
    private var entriesLast7Days: [DailyEntryCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let countsByDay = Dictionary(grouping: journalEntries) { entry in
            calendar.startOfDay(for: entry.createdAt)
        }.mapValues(\.count)

        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            return DailyEntryCount(day: day, count: countsByDay[day] ?? 0)
        }
    }
    
    private var sortedAchievementUnlocks: [AchievementUnlock] {
        achievementUnlocks.sorted { ($0.achievementKind?.rawValue ?? "") < ($1.achievementKind?.rawValue ?? "") }
    }

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
                    DashboardStatCard(label: L10n.Dashboard.lastActivityLabel, value: lastActivityText)
                    DashboardStatCard(label: L10n.Dashboard.streakLabel, value: L10n.Dashboard.streakValue(currentStreak))
                    DashboardStatCard(label: L10n.Dashboard.journalEntriesLabel, value: "\(journalEntries.count)")
                }
                
                DashboardSectionCard(title: L10n.Dashboard.entriesOverTimeLabel) {
                    Chart(entriesLast7Days) { item in
                        BarMark(
                            x: .value("Day", item.day, unit: .day),
                            y: .value("Entries", item.count)
                        )
                        .foregroundStyle(
                            Calendar.current.isDateInToday(item.day) ? Theme.textPrimary : Theme.textFaint
                        )
                        .cornerRadius(3)
                    }
                    .frame(height: 70)
                    .chartYAxis(.hidden)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(weekdayLabel(for: date))
                                        .font(Typography.caption)
                                        .foregroundStyle(Theme.textFaint)
                                }
                            }
                        }
                    }
                }
                
                DashboardSelfLetterRow(
                    onWriteTapped: { /* TODO: otworzyć compose listu */ },
                    onOpenTapped: { /* TODO: otworzyć dostępny list */ }
                )
                
                DashboardAchievementsSection(
                    unlocks: sortedAchievementUnlocks,
                    onTapIcon: { unlock in selectedUnlock = unlock },
                    onTapHeader: { isAchievementsScreenShown = true }
                )
                
                Spacer()
            }
            .padding(28)
            
            if let selectedUnlock {
                AchievementDetailOverlay(unlock: selectedUnlock, onClose: { self.selectedUnlock = nil })
            }
            
            if isAchievementsScreenShown {
                AchievementsView(
                    unlocks: sortedAchievementUnlocks,
                    onBack: { isAchievementsScreenShown = false }
                )
            }
        }
        .onAppear {
            updateGreetingIfNeeded()
            _ = achievementService.allUnlocks(modelContext: modelContext)
            SelfLetterService.refreshAvailability(context: modelContext)
        }
        .onChange(of: languageManager.current) { _, _ in
            updateGreetingIfNeeded()
        }
        .onChange(of: username) { _, _ in
            updateGreetingIfNeeded()
        }
    }

    private func updateGreetingIfNeeded() {
        let todayString = Date().dayKey

        if greetingDateString != todayString {
            greetingIndex = L10n.Dashboard.greetings.indices.randomElement() ?? 0
            greetingDateString = todayString
        }

        let name = username.isEmpty ? L10n.Dashboard.fallbackName : username
        greetingText = L10n.Dashboard.greetings[greetingIndex]
            .replacingOccurrences(of: "{name}", with: name)
    }
    
    private func weekdayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: L10n.lang == .pl ? "pl_PL" : "en_US")
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date)
    }
}

private struct DailyEntryCount: Identifiable {
    let day: Date
    let count: Int
    var id: Date { day }
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
        
        static func streakValue(_ days: Int) -> String {
            switch lang {
            case .en: return days == 1 ? "1 day" : "\(days) days"
            case .pl: return days == 1 ? "1 dzień" : "\(days) dni"
            }
        }

        static var noActivityYet: String {
            switch lang {
            case .en: return "No activity yet"
            case .pl: return "Brak aktywności"
            }
        }
        
        static var entriesOverTimeLabel: String {
            switch lang {
            case .pl: return "WPISY W CZASIE"
            case .en: return "ENTRIES OVER TIME"
            }
        }
        
        static var achievementsLabel: String {
            switch lang {
            case .pl: return "Osiągnięcia"
            case .en: return "Achievements"
            }
        }
    }
}
