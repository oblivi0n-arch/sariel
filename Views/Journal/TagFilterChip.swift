import SwiftUI

struct TagFilterChip: View {
    let tag: JournalEntryTag
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Text("#\(tag.name)")
            .font(Typography.caption)
            .foregroundStyle(isSelected ? Theme.background : Theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Theme.textPrimary : Theme.fieldBackground)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
            .contentShape(Capsule())
            .onTapGesture(perform: onToggle)
    }
}
