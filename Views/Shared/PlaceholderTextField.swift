import SwiftUI

struct PlaceholderTextField: View {
    let placeholder: String
    @Binding var text: String

    var font: Font = Theme.uiFont
    var textColor: Color = Theme.textPrimary
    var placeholderColor: Color = Theme.textFaint
    var axis: Axis = .horizontal
    var textAlignment: TextAlignment = .leading

    private var stackAlignment: Alignment {
        switch textAlignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    var body: some View {
        ZStack(alignment: stackAlignment) {
            if text.isEmpty {
                Text(placeholder)
                    .font(font)
                    .foregroundStyle(placeholderColor)
                    .multilineTextAlignment(textAlignment)
                    .frame(maxWidth: .infinity, alignment: stackAlignment)
                    .allowsHitTesting(false)
            }

            TextField("", text: $text, axis: axis)
                .textFieldStyle(.plain)
                .font(font)
                .foregroundStyle(textColor)
                .multilineTextAlignment(textAlignment)
        }
    }
}
