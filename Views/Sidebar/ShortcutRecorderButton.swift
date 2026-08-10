import SwiftUI

struct ShortcutRecorderButton: View {
    @Binding var shortcut: AppKeyboardShortcut
    var isTaken: (AppKeyboardShortcut) -> Bool = { _ in false }

    @State private var isRecording = false
    @State private var hasConflict = false
    @FocusState private var isFocused: Bool

    private var label: String {
        if hasConflict { return L10n.Settings.shortcutConflict }
        return isRecording ? L10n.Settings.shortcutRecording : shortcut.displayString
    }

    private var labelColor: Color {
        if hasConflict { return Color.orange.opacity(0.9) }
        return isRecording ? Theme.textPrimary : Theme.textFaint
    }

    private var borderColor: Color {
        if hasConflict { return Color.orange.opacity(0.7) }
        return isRecording ? Theme.borderStrong : Theme.border
    }

    var body: some View {
        Button(action: startRecording) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(labelColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .frame(minWidth: 44)
                .contentShape(Rectangle())
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(borderColor, lineWidth: hasConflict ? 1 : 0.5)
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
        .animation(.easeInOut(duration: 0.2), value: hasConflict)
    }

    private func startRecording() {
        hasConflict = false
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

        let candidate = AppKeyboardShortcut(key: String(char), modifiers: mods.rawValue)

        guard !isTaken(candidate) else {
            isRecording = false
            hasConflict = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                hasConflict = false
            }
            return .handled
        }

        shortcut = candidate
        isRecording = false
        return .handled
    }
}
