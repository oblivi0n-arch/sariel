import SwiftUI
import AppKit

private struct HoverBorderEffect<S: Shape>: ViewModifier {
    @State private var isHovering = false
    var shape: S

    func body(content: Content) -> some View {
        content
            .overlay(
                shape
                    .stroke(Theme.textPrimary.opacity(0.45), lineWidth: 1)
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
    func hoverBorder<S: Shape>(_ shape: S) -> some View {
        modifier(HoverBorderEffect(shape: shape))
    }

    func hoverBorder(cornerRadius: CGFloat = 8) -> some View {
        hoverBorder(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
