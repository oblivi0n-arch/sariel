import SwiftUI

struct LanguageOptionButton: View {
    @ObservedObject private var languageManager = LanguageManager.shared

    let language: AppLanguage
    let label: String

    var body: some View {
        let isSelected = languageManager.current == language

        Button(action: { languageManager.current = language }) {
            Text(label)
                .font(Typography.label)
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textMuted)
                .frame(width: 52, height: 32)
                .contentShape(Rectangle())
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Theme.borderStrong : Theme.border, lineWidth: isSelected ? 1 : 0.5)
                )
                .hoverBorder(cornerRadius: 8)
        }
        .buttonStyle(.plain)
    }
}
