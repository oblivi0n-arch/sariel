import SwiftUI
import AppKit

private struct HoverBorderEffect: ViewModifier {
    @State private var isHovering = false
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.borderStrong, lineWidth: 0.5)
                    .opacity(isHovering ? 1 : 0)
            )
            .animation(.easeOut(duration: 0.15), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

extension View {
    func hoverBorder(cornerRadius: CGFloat = 8) -> some View {
        modifier(HoverBorderEffect(cornerRadius: cornerRadius))
    }
}
