import SwiftUI

struct SelfLetterArchiveRow: View {
    let letter: SelfLetter
    let searchText: String
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HighlightedText(
                    text: letter.title?.isEmpty == false ? letter.title! : L10n.SelfLetterArchive.untitled,
                    searchText: searchText,
                    font: Typography.title,
                    baseColor: Theme.textPrimary
                )

                Spacer()

                if let openedAt = letter.openedAt {
                    Text(openedAt, style: .date)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                }
            }

            HighlightedText(
                text: letter.content,
                searchText: searchText,
                font: Theme.uiFont,
                baseColor: Theme.textSecondary
            )
            .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fieldBackground)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isHovering ? Theme.borderStrong : Theme.border, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
    }
}
