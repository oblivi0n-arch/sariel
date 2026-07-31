import SwiftUI
import SwiftData

struct SelfLetterCard: View {
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
    
    private var isInteractive: Bool {
        canWriteNewLetter || availableCount > 0
    }
    
    private var envelopeIcon: String {
        if availableCount > 0 {
            "envelope.open"
        } else if sealedLetters.count > 1 {
            "envelope.stack"
        } else {
            "envelope"
        }
    }
    
    private var statusText: String {
        if availableCount > 0 {
            return L10n.Dashboard.selfLetterAvailable
        } else if let nextOpenDate = sealedLetters.map(\.openDate).min() {
            return L10n.Dashboard.selfLetterSealed(daysUntil(nextOpenDate))
        } else {
            return L10n.Dashboard.selfLetterEmpty
        }
    }
    
    private func daysUntil(_ date: Date) -> Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0)
    }
    
    var body: some View {
        Group {
            if isInteractive {
                cardBody.hoverScale()
            } else {
                cardBody
            }
        }
        .onTapGesture {
            guard isInteractive else { return }
            if availableCount > 0 {
                onOpenTapped()
            } else {
                onWriteTapped()
            }
        }
    }
    
    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.Dashboard.selfLetterLabel)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
                .tracking(1)
            
            Image(systemName: envelopeIcon)
                .font(.system(size: 18))
                .foregroundStyle(availableCount > 0 ? Theme.textPrimary : Theme.textMuted)
            
            Text(statusText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(availableCount > 0 ? Theme.textPrimary : Theme.textSecondary)
            
            if !canWriteNewLetter {
                Text(L10n.Dashboard.selfLetterLimitReached)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(availableCount > 0 ? Theme.borderStrong : Theme.border, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
    }
}

#Preview("Brak listów") {
    let container = try! ModelContainer(for: SelfLetter.self, configurations: .init(isStoredInMemoryOnly: true))
    return SelfLetterCard()
        .modelContainer(container)
        .padding(40)
        .frame(width: 260)
        .background(Theme.background)
}

#Preview("Zapieczętowany (kilka)") {
    let container = try! ModelContainer(for: SelfLetter.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext
    context.insert(SelfLetter(content: "test", openDate: SelfLetterDelay.oneWeek.openDate()))
    context.insert(SelfLetter(content: "test", openDate: SelfLetterDelay.oneMonth.openDate()))
    return SelfLetterCard()
        .modelContainer(container)
        .padding(40)
        .frame(width: 260)
        .background(Theme.background)
}

#Preview("Dostępny do odczytania") {
    let container = try! ModelContainer(for: SelfLetter.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext
    let letter = SelfLetter(content: "test", openDate: Date())
    letter.letterStatus = .available
    context.insert(letter)
    return SelfLetterCard()
        .modelContainer(container)
        .padding(40)
        .frame(width: 260)
        .background(Theme.background)
}

extension L10n.Dashboard {
    static var selfLetterLabel: String {
        switch L10n.lang {
        case .pl: return "LIST DO SIEBIE"
        case .en: return "SELF LETTER"
        }
    }
    
    static var selfLetterEmpty: String {
        switch L10n.lang {
        case .pl: return "napisz list do przyszłego siebie"
        case .en: return "write a letter to your future self"
        }
    }
    
    static func selfLetterSealed(_ days: Int) -> String {
        switch L10n.lang {
        case .pl: return days <= 0 ? "otworzy się dziś" : (days == 1 ? "otworzy się za 1 dzień" : "otworzy się za \(days) dni")
        case .en: return days <= 0 ? "opens today" : (days == 1 ? "opens in 1 day" : "opens in \(days) days")
        }
    }
    
    static var selfLetterAvailable: String {
        switch L10n.lang {
        case .pl: return "masz list czekający na Ciebie"
        case .en: return "you have a letter waiting"
        }
    }
    
    static var selfLetterLimitReached: String {
        switch L10n.lang {
        case .pl: return "limit listów wyczerpany"
        case .en: return "letter limit reached"
        }
    }
}
