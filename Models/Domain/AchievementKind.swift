import Foundation

enum AchievementKind: String, CaseIterable {
    // MARK: - Behavioral / consistency
    case nightOwl              // writing between 00:00 and 04:00
    case consistencyStreak     // entries without a gap for X days
    case returnedAfterSilence  // came back after a long gap (21+ days)
    case writingSpiral         // several entries in a short time window

    // MARK: - Honesty / Commitment
    case commitmentsKept       // X kept commitments in a row
    case commitmentsBroken     // X broken commitments in a row
    case credibilityRecovered  // credibilityBand: .poor -> .solid
    case firstKeptAfterBroken  // first kept commitment after a broken streak

    // MARK: - Tribunal
    case tribunalFaced             // first time facing the tribunal
    case tribunalVerdictsAccepted  // number of uncomfortable verdicts accepted

    // MARK: - Thematic patterns
    case recurringTag          // same tag keeps reappearing across entries
    
    // MARK: - Self Letters
    case selfLetterFirstSealed     // first letter sealed to future self
    case selfLetterFirstOpened     // first letter opened
    case selfLetterLongestDelay    // sealed a letter with the 1-year delay

    // MARK: - Meditation
    case meditationConsistency      // meditation sessions X days in a row
    case meditationAbandonedPattern // sessions interrupted X times in a row
    case meditationFirstFullSession // first session completed without interruption

    var symbolName: String {
        switch self {
        case .nightOwl: "moon.stars"
        case .consistencyStreak: "flame"
        case .returnedAfterSilence: "arrow.uturn.backward"
        case .writingSpiral: "tornado"
        case .commitmentsKept: "checkmark.seal"
        case .commitmentsBroken: "xmark.seal"
        case .credibilityRecovered: "arrow.up.right"
        case .firstKeptAfterBroken: "arrow.triangle.turn.up.right.diamond"
        case .tribunalFaced: "building.columns"
        case .tribunalVerdictsAccepted: "checkmark.shield"
        case .recurringTag: "repeat"
        case .selfLetterFirstSealed: "envelope"
        case .selfLetterFirstOpened: "envelope.open"
        case .selfLetterLongestDelay: "hourglass"
        case .meditationConsistency: "leaf"
        case .meditationAbandonedPattern: "wind"
        case .meditationFirstFullSession: "checkmark.circle"
        }
    }

    var isProgressive: Bool {
        switch self {
        case .nightOwl: true
        case .consistencyStreak: true
        case .returnedAfterSilence: false
        case .writingSpiral: false
        case .commitmentsKept: true
        case .commitmentsBroken: true
        case .credibilityRecovered: false
        case .firstKeptAfterBroken: false
        case .tribunalFaced: false
        case .tribunalVerdictsAccepted: true
        case .recurringTag: true
        case .selfLetterFirstSealed: false
        case .selfLetterFirstOpened: false
        case .selfLetterLongestDelay: false
        case .meditationConsistency: true
        case .meditationAbandonedPattern: true
        case .meditationFirstFullSession: false
        }
    }

    var targetCount: Int? {
        switch self {
        case .nightOwl: 7
        case .consistencyStreak: 14
        case .returnedAfterSilence: nil
        case .writingSpiral: nil
        case .commitmentsKept: 5
        case .commitmentsBroken: 3
        case .credibilityRecovered: nil
        case .firstKeptAfterBroken: nil
        case .tribunalFaced: nil
        case .tribunalVerdictsAccepted: 5
        case .recurringTag: 5
        case .selfLetterFirstSealed: nil
        case .selfLetterFirstOpened: nil
        case .selfLetterLongestDelay: nil
        case .meditationConsistency: 7
        case .meditationAbandonedPattern: 3
        case .meditationFirstFullSession: nil
        }
    }
}

extension AchievementKind {
    var title: String {
        switch (self, L10n.lang) {
        case (.nightOwl, .pl): return "Nocny ptak"
        case (.nightOwl, .en): return "Night Owl"
        case (.consistencyStreak, .pl): return "Regularność"
        case (.consistencyStreak, .en): return "Consistency"
        case (.returnedAfterSilence, .pl): return "Powrót"
        case (.returnedAfterSilence, .en): return "The Return"
        case (.writingSpiral, .pl): return "Spirala"
        case (.writingSpiral, .en): return "Spiral"
        case (.commitmentsKept, .pl): return "Słowo dotrzymane"
        case (.commitmentsKept, .en): return "Word Kept"
        case (.commitmentsBroken, .pl): return "Wzorzec"
        case (.commitmentsBroken, .en): return "A Pattern"
        case (.credibilityRecovered, .pl): return "Odbudowa"
        case (.credibilityRecovered, .en): return "Rebuilt"
        case (.firstKeptAfterBroken, .pl): return "Przełamanie"
        case (.firstKeptAfterBroken, .en): return "The Break"
        case (.tribunalFaced, .pl): return "Trybunał"
        case (.tribunalFaced, .en): return "The Tribunal"
        case (.tribunalVerdictsAccepted, .pl): return "Bez ucieczki"
        case (.tribunalVerdictsAccepted, .en): return "No Escape"
        case (.recurringTag, .pl): return "Powtórka"
        case (.recurringTag, .en): return "Recurring"
        case (.selfLetterFirstSealed, .pl): return "Do przyszłości"
        case (.selfLetterFirstSealed, .en): return "To the Future"
        case (.selfLetterFirstOpened, .pl): return "Konfrontacja z przeszłością"
        case (.selfLetterFirstOpened, .en): return "Facing the Past"
        case (.selfLetterLongestDelay, .pl): return "Rok ciszy"
        case (.selfLetterLongestDelay, .en): return "A Year of Silence"
        case (.meditationConsistency, .pl): return "Cisza jako nawyk"
        case (.meditationConsistency, .en): return "Silence as Habit"
        case (.meditationAbandonedPattern, .pl): return "Ucieczka od ciszy"
        case (.meditationAbandonedPattern, .en): return "Fleeing the Silence"
        case (.meditationFirstFullSession, .pl): return "Dosiedziałeś"
        case (.meditationFirstFullSession, .en): return "Sat It Out"
        }
    }

    var unlockedDescription: String {
        switch (self, L10n.lang) {
        case (.nightOwl, .pl): return "Piszesz między północą a czwartą. To już siódmy raz."
        case (.nightOwl, .en): return "You write between midnight and 4am. Seven times now."
        case (.consistencyStreak, .pl): return "14 dni bez przerwy. Sprawdź, czy to nawyk, czy unikanie czegoś innego."
        case (.consistencyStreak, .en): return "14 days without a gap. Check whether that's a habit or an avoidance."
        case (.returnedAfterSilence, .pl): return "Zniknąłeś na ponad 3 tygodnie. Wróciłeś."
        case (.returnedAfterSilence, .en): return "You disappeared for over 3 weeks. You came back."
        case (.writingSpiral, .pl): return "Kilka wpisów w ciągu godziny. To przetwarzanie, czy ucieczka?"
        case (.writingSpiral, .en): return "Several entries within an hour. Processing, or escaping?"
        case (.commitmentsKept, .pl): return "5 dotrzymanych deklaracji z rzędu."
        case (.commitmentsKept, .en): return "5 kept commitments in a row."
        case (.commitmentsBroken, .pl): return "3 złamane deklaracje z rzędu. To już wzorzec, nie wypadek."
        case (.commitmentsBroken, .en): return "3 broken commitments in a row. That's a pattern, not an accident."
        case (.credibilityRecovered, .pl): return "Twoja wiarygodność przeszła z niskiej do solidnej."
        case (.credibilityRecovered, .en): return "Your credibility moved from poor to solid."
        case (.firstKeptAfterBroken, .pl): return "Pierwsza dotrzymana deklaracja po serii złamanych."
        case (.firstKeptAfterBroken, .en): return "First kept commitment after a broken streak."
        case (.tribunalFaced, .pl): return "Pierwszy raz stanąłeś przed trybunałem."
        case (.tribunalFaced, .en): return "You faced the tribunal for the first time."
        case (.tribunalVerdictsAccepted, .pl): return "5 niewygodnych werdyktów przyjętych bez ucieczki."
        case (.tribunalVerdictsAccepted, .en): return "5 uncomfortable verdicts accepted without escaping."
        case (.recurringTag, .pl): return "Ten sam temat wraca. Piąty raz."
        case (.recurringTag, .en): return "The same topic keeps coming back. Fifth time now."
        case (.selfLetterFirstSealed, .pl): return "Zapieczętowałeś list do siebie z przyszłości. Zobaczymy, czy dotrzymasz obietnic."
        case (.selfLetterFirstSealed, .en): return "You sealed a letter to your future self. Let's see if you keep the promises."
        case (.selfLetterFirstOpened, .pl): return "Otworzyłeś list od siebie sprzed miesięcy. Czas skonfrontować się z tym, kim byłeś."
        case (.selfLetterFirstOpened, .en): return "You opened a letter from your past self. Time to face who you were."
        case (.selfLetterLongestDelay, .pl): return "Zapieczętowałeś list na rok. Ufasz, że to przeczytasz — czy liczysz, że o tym zapomnisz?"
        case (.selfLetterLongestDelay, .en): return "You sealed a letter for a year from now. Do you trust you'll read it — or hope you'll forget?"
        case (.meditationConsistency, .pl): return "7 dni medytacji z rzędu. Sprawdź, czy to spokój, czy kolejny nawyk do wypełnienia czasu."
        case (.meditationConsistency, .en): return "7 days of meditation in a row. Check whether that's calm, or another habit filling time."
        case (.meditationAbandonedPattern, .pl): return "3 przerwane sesje z rzędu. Uciekasz przed ciszą, czy przed tym, co w niej wychodzi na wierzch?"
        case (.meditationAbandonedPattern, .en): return "3 interrupted sessions in a row. Are you fleeing the silence, or what surfaces in it?"
        case (.meditationFirstFullSession, .pl): return "Pierwszy raz dosiedziałeś do końca. Bez przerywania, bez wymówki."
        case (.meditationFirstFullSession, .en): return "First time you sat it out to the end. No interrupting, no excuse."
        }
    }

    var hintText: String {
        switch (self, L10n.lang) {
        case (.nightOwl, .pl): return "Coś związanego z porą, o której piszesz."
        case (.nightOwl, .en): return "Something about the time you write."
        case (.consistencyStreak, .pl): return "Coś związanego z regularnością Twoich wpisów."
        case (.consistencyStreak, .en): return "Something about how regularly you write."
        case (.returnedAfterSilence, .pl): return "Coś związanego z przerwami w pisaniu."
        case (.returnedAfterSilence, .en): return "Something about the gaps between entries."
        case (.writingSpiral, .pl): return "Coś związanego z tempem Twojego pisania."
        case (.writingSpiral, .en): return "Something about the pace you write at."
        case (.commitmentsKept, .pl): return "Coś związanego z dotrzymywaniem słowa."
        case (.commitmentsKept, .en): return "Something about keeping your word."
        case (.commitmentsBroken, .pl): return "Coś związanego z niedotrzymanymi obietnicami."
        case (.commitmentsBroken, .en): return "Something about broken promises."
        case (.credibilityRecovered, .pl): return "Coś związanego z Twoją wiarygodnością."
        case (.credibilityRecovered, .en): return "Something about your credibility."
        case (.firstKeptAfterBroken, .pl): return "Coś związanego ze zmianą wzorca."
        case (.firstKeptAfterBroken, .en): return "Something about breaking a pattern."
        case (.tribunalFaced, .pl): return "Coś związanego z konfrontacją."
        case (.tribunalFaced, .en): return "Something about facing a confrontation."
        case (.tribunalVerdictsAccepted, .pl): return "Coś związanego z przyjmowaniem werdyktów."
        case (.tribunalVerdictsAccepted, .en): return "Something about accepting a verdict."
        case (.recurringTag, .pl): return "Coś związanego z tematami, które wracają."
        case (.recurringTag, .en): return "Something about topics that keep returning."
        case (.selfLetterFirstSealed, .pl): return "Coś związanego z pisaniem do siebie z przyszłości."
        case (.selfLetterFirstSealed, .en): return "Something about writing to your future self."
        case (.selfLetterFirstOpened, .pl): return "Coś związanego z otwieraniem listu od siebie."
        case (.selfLetterFirstOpened, .en): return "Something about opening a letter from yourself."
        case (.selfLetterLongestDelay, .pl): return "Coś związanego z tym, jak długo czekasz na odpowiedź od siebie."
        case (.selfLetterLongestDelay, .en): return "Something about how long you wait to hear from yourself."
        case (.meditationConsistency, .pl): return "Coś związanego z regularnością Twoich medytacji."
        case (.meditationConsistency, .en): return "Something about how regularly you meditate."
        case (.meditationAbandonedPattern, .pl): return "Coś związanego z przerywaniem sesji medytacji."
        case (.meditationAbandonedPattern, .en): return "Something about interrupting meditation sessions."
        case (.meditationFirstFullSession, .pl): return "Coś związanego z dosiedzeniem sesji do końca."
        case (.meditationFirstFullSession, .en): return "Something about sitting a session out to the end."
        }
    }
}
