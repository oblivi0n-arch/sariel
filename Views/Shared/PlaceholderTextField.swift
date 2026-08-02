import SwiftUI

struct PlaceholderTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var font: Font = Theme.uiFont
    var textColor: Color = Theme.textPrimary
    var placeholderColor: Color = Theme.textFaint
    var axis: Axis = .horizontal
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(font)
                    .foregroundStyle(placeholderColor)
                    .allowsHitTesting(false)
            }
            
            TextField("", text: $text, axis: axis)
                .textFieldStyle(.plain)
                .font(font)
                .foregroundStyle(textColor)
        }
    }
}
