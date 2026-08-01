import SwiftUI

struct SelfLetterArchiveRow: View {
    let letter: SelfLetter
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(letter.title?.isEmpty == false ? letter.title! : L10n.SelfLetterArchive.untitled)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                if let openedAt = letter.openedAt {
                    Text(openedAt, style: .date)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                }
            }

            Text(letter.content)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)
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
