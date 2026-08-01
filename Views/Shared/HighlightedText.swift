import SwiftUI

struct HighlightedText: View {
    let text: String
    let searchText: String
    var font: Font = Theme.uiFont
    var baseColor: Color = Theme.textPrimary
    var highlightColor: Color = Theme.textPrimary

    var body: some View {
        Text(makeAttributedString())
    }

    private func makeAttributedString() -> AttributedString {
        var result = AttributedString(text)
        result.font = font
        result.foregroundColor = baseColor

        guard !searchText.isEmpty else { return result }

        var searchRangeStart = text.startIndex
        while searchRangeStart < text.endIndex,
              let foundRange = text.range(
                of: searchText,
                options: .caseInsensitive,
                range: searchRangeStart..<text.endIndex
              ),
              let attributedRange = Range(foundRange, in: result) {

            result[attributedRange].foregroundColor = highlightColor
            result[attributedRange].backgroundColor = highlightColor.opacity(0.25)
            result[attributedRange].font = font.bold()

            searchRangeStart = foundRange.upperBound
        }

        return result
    }
}
