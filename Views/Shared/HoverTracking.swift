import SwiftUI
import AppKit

private struct HoverTracking: ViewModifier {
    @Binding var isHovering: Bool

    func body(content: Content) -> some View {
        content.onHover { hovering in
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
    func trackHover(_ isHovering: Binding<Bool>) -> some View {
        trackHover(isHovering, shape: Rectangle())
    }

    func trackHover<S: Shape>(_ isHovering: Binding<Bool>, shape: S) -> some View {
        self
            .contentShape(shape)
            .modifier(HoverTracking(isHovering: isHovering))
    }
}
