import SwiftUI

struct JournalEntryRow: View {
    let entry: JournalEntry
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.entryMood.symbolName)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textFaint)

            Text(entry.title)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            Text(entry.createdAt, style: .date)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textFaint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovering ? Theme.fieldBackground : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
    }
}
