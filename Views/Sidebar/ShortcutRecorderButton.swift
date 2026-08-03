import SwiftUI

struct ShortcutRecorderButton: View {
    @Binding var shortcut: AppKeyboardShortcut
    @State private var isRecording = false
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: startRecording) {
            Text(isRecording ? L10n.Settings.shortcutRecording : shortcut.displayString)
                .font(Typography.caption)
                .foregroundStyle(isRecording ? Theme.textPrimary : Theme.textFaint)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .frame(minWidth: 44)
                .contentShape(Rectangle())
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isRecording ? Theme.borderStrong : Theme.border, lineWidth: 0.5)
                )
                .hoverBorder(cornerRadius: 5)
        }
        .buttonStyle(.plain)
        .focusable()
        .focused($isFocused)
        .onKeyPress(phases: .down) { press in
            guard isRecording else { return .ignored }
            return handle(press)
        }
    }

    private func startRecording() {
        isRecording = true
        isFocused = true
    }

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        if press.key == .escape {
            isRecording = false
            return .handled
        }

        guard let char = press.characters.lowercased().first else {
            return .handled
        }

        var mods: EventModifiers = []
        if press.modifiers.contains(.command) { mods.insert(.command) }
        if press.modifiers.contains(.shift)   { mods.insert(.shift) }
        if press.modifiers.contains(.option)  { mods.insert(.option) }
        if press.modifiers.contains(.control) { mods.insert(.control) }

        shortcut = AppKeyboardShortcut(key: String(char), modifiers: mods.rawValue)
        isRecording = false
        return .handled
    }
}
