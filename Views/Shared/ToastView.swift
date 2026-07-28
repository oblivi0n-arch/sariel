import SwiftUI

struct ToastView: View {
    let toast: Toast
    let onTap: () -> Void
    
    @State private var progress: CGFloat = 1
    
    private var icon: String {
        switch toast.kind {
        case .journalEntrySaved: return "book.closed"
        case .declarationLimitBlocked: return "hand.raised.fill"
        case .declarationRequiresNewMessage: return "hand.raised.fill"
        case .achievementUnlocked(let kind): return kind.symbolName
        }
    }
    
    private var title: String {
        switch toast.kind {
        case .journalEntrySaved(let entry): return entry.title
        case .declarationLimitBlocked: return L10n.Toast.declarationBlockedTitle
        case .declarationRequiresNewMessage: return L10n.Toast.declarationBlockedTitle
        case .achievementUnlocked(let kind): return kind.title
        }
    }
    
    private var subtitle: String {
        switch toast.kind {
        case .journalEntrySaved: return L10n.Toast.entrySaved
        case .declarationLimitBlocked: return L10n.Toast.resolveOneFirst
        case .declarationRequiresNewMessage: return L10n.Toast.editIntoNewMessage
        case .achievementUnlocked(let kind): return kind.unlockedDescription
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(Typography.iconSmall)
                    .foregroundStyle(Theme.textPrimary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.label)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            
            GeometryReader { geo in
                Rectangle()
                    .fill(Theme.textPrimary)
                    .frame(width: geo.size.width * progress, height: 2)
            }
            .frame(height: 2)
        }
        .frame(width: 220)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.border, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.5), radius: 20, y: 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onAppear {
            withAnimation(.linear(duration: toast.duration)) {
                progress = 0
            }
        }
    }
}

extension L10n {
    enum Toast {
        static var declarationBlockedTitle: String {
            switch lang {
            case .en: return "Declaration blocked"
            case .pl: return "Deklaracja zablokowana"
            }
        }
        
        static var entrySaved: String {
            switch lang {
            case .en: return "entry saved"
            case .pl: return "wpis zapisany"
            }
        }
        
        static var resolveOneFirst: String {
            switch lang {
            case .en: return "resolve one before adding another"
            case .pl: return "rozstrzygnij jedno, zanim dodasz kolejne"
            }
        }
        
        static var editIntoNewMessage: String {
            switch lang {
            case .en: return "edit into a new message instead"
            case .pl: return "zamiast tego edytuj jako nową wiadomość"
            }
        }
    }
}
