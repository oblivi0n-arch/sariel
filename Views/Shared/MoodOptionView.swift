import SwiftUI

struct MoodOptionView: View {
    let mood: Mood
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: mood.symbolName)
                .font(Typography.icon)

            Text(mood.displayName)
                .font(.system(size: 9))
        }
        .foregroundStyle(foregroundColor)
        .frame(width: 44, height: 44)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: isSelected ? 1 : 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { hovering in isHovering = hovering }
    }

    private var foregroundColor: Color {
        if isSelected { return Theme.textPrimary }
        if isHovering { return Theme.textMuted }
        return Theme.textFaint
    }

    private var backgroundColor: Color {
        isSelected ? Theme.fieldBackground : .clear
    }

    private var borderColor: Color {
        if isSelected { return Theme.border }
        if isHovering { return Theme.border }
        return .clear
    }
}
