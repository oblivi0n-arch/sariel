import SwiftUI
import SwiftData

struct JournalEntryDetailView: View {
    @Bindable var entry: JournalEntry
    @Binding var isEditing: Bool
    let onOpenConversation: (Conversation) -> Void
    let achievementService: AchievementService
    
    var body: some View {
        if isEditing {
            JournalEntryEditor(entry: entry, achievementService: achievementService)
        } else {
            JournalEntryReader(entry: entry, onEdit: { isEditing = true }, onOpenConversation: onOpenConversation)
        }
    }
}

struct JournalEntryReader: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isHoveringViewConversation = false
    
    let entry: JournalEntry
    let onEdit: () -> Void
    let onOpenConversation: (Conversation) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            Rectangle().fill(Theme.border).frame(height: 0.5)
            
            Text(entry.content)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(4)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
            
            if !entry.tags.isEmpty || entry.sourceConversation != nil {
                Rectangle().fill(Theme.border).frame(height: 0.5)
                footer
            }
        }
        .padding(16)
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: entry.entryMood.symbolName)
                        .font(Typography.iconSmall)
                    Text(entry.entryMood.displayName)
                        .font(Typography.caption)
                }
                .foregroundStyle(Theme.textFaint)
                
                Text(entry.title)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)
                
                Text(entry.createdAt, style: .date)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
            }
            
            Spacer()
            
            Button(action: togglePin) {
                Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                    .font(Typography.iconButton)
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                    .hoverBorder(Circle())
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(Typography.iconButton)
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                    .hoverBorder(Circle())
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
    
    private var footer: some View {
        HStack {
            if !entry.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(entry.tags.sorted(by: { $0.name < $1.name })) { tag in
                        Text("#\(tag.name)")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }
            
            Spacer()
            
            if let conversation = entry.sourceConversation {
                Button(action: { onOpenConversation(conversation) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                        Text(L10n.JournalDetail.viewConversation)
                    }
                    .font(Typography.label)
                    .foregroundStyle(isHoveringViewConversation ? Theme.textPrimary : Theme.textMuted)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .trackHover($isHoveringViewConversation)
            }
        }
    }
    
    private func togglePin() {
        entry.isPinned.toggle()
        try? modelContext.save()
    }
}

extension L10n {
    enum JournalDetail {
        static var viewConversation: String {
            switch lang {
            case .en: return "View conversation"
            case .pl: return "Zobacz rozmowę"
            }
        }
    }
}
