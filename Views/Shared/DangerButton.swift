import SwiftUI

struct DangerButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.label)
                .foregroundStyle(Color.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(isHovering && isEnabled ? 0.18 : 0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(isHovering && isEnabled ? 0.7 : 0.4), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .trackHover($isHovering)
    }
}
