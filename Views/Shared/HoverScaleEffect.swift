import SwiftUI
import AppKit

private struct HoverScaleEffect: ViewModifier {
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? 1.05 : 1.0)
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
    func hoverScale() -> some View {
        modifier(HoverScaleEffect())
    }
}
