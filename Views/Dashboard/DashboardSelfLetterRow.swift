import SwiftUI
import SwiftData

struct DashboardSelfLetterRow: View {
    @Query private var letters: [SelfLetter]
    var onWriteTapped: () -> Void = {}
    var onOpenTapped: () -> Void = {}
    
    private var sealedLetters: [SelfLetter] {
        letters.filter { $0.letterStatus == .sealed }
    }
    
    private var availableCount: Int {
        letters.filter { $0.letterStatus == .available }.count
    }
    
    private var canWriteNewLetter: Bool {
        letters.filter { $0.letterStatus != .opened }.count < SelfLetter.maxActiveLetters
    }
    
    private var sealedValueText: String {
        guard let nextOpenDate = sealedLetters.map(\.openDate).min() else {
            return L10n.Dashboard.selfLetterNoneSealed
        }
        let days = max(0, Calendar.current.dateComponents([.day], from: Date(), to: nextOpenDate).day ?? 0)
        return L10n.Dashboard.selfLetterSealed(days)
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            DashboardStatCard(
                label: L10n.Dashboard.selfLetterSealedLabel,
                value: sealedValueText,
                icon: sealedLetters.count > 1 ? "envelope.stack" : "envelope"
            )
            
            DashboardStatCard(
                label: L10n.Dashboard.selfLetterAvailableLabel,
                value: L10n.Dashboard.selfLetterAvailableValue(availableCount),
                icon: "envelope.open",
                isAccented: availableCount > 0,
                onTap: availableCount > 0 ? onOpenTapped : nil
            )
            
            DashboardStatCard(
                label: L10n.Dashboard.selfLetterWriteLabel,
                value: canWriteNewLetter ? L10n.Dashboard.selfLetterWriteValue : L10n.Dashboard.selfLetterLimitReached,
                icon: "square.and.pencil",
                onTap: canWriteNewLetter ? onWriteTapped : nil
            )
        }
    }
}

extension L10n.Dashboard {
    static var selfLetterSealedLabel: String {
        switch L10n.lang {
        case .pl: return "ZAPIECZĘTOWANE LISTY"
        case .en: return "SEALED LETTERS"
        }
    }

    static var selfLetterNoneSealed: String {
        switch L10n.lang {
        case .pl: return "brak"
        case .en: return "none"
        }
    }

    static func selfLetterSealed(_ days: Int) -> String {
        switch L10n.lang {
        case .pl: return days == 0 ? "dziś" : (days == 1 ? "za 1 dzień" : "za \(days) dni")
        case .en: return days == 0 ? "today" : (days == 1 ? "in 1 day" : "in \(days) days")
        }
    }

    static var selfLetterAvailableLabel: String {
        switch L10n.lang {
        case .pl: return "DOSTĘPNE LISTY"
        case .en: return "AVAILABLE LETTERS"
        }
    }

    static func selfLetterAvailableValue(_ count: Int) -> String {
        switch L10n.lang {
        case .pl: return count == 0 ? "brak" : "\(count) czeka"
        case .en: return count == 0 ? "none" : "\(count) waiting"
        }
    }

    static var selfLetterWriteLabel: String {
        switch L10n.lang {
        case .pl: return "NOWY LIST"
        case .en: return "NEW LETTER"
        }
    }

    static var selfLetterWriteValue: String {
        switch L10n.lang {
        case .pl: return "napisz do siebie"
        case .en: return "write to yourself"
        }
    }

    static var selfLetterLimitReached: String {
        switch L10n.lang {
        case .pl: return "limit wyczerpany"
        case .en: return "limit reached"
        }
    }
}
