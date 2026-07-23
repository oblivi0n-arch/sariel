import SwiftUI

struct FailureMeaningPromptView: View {
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var answer: String = ""
    @FocusState private var isFocused: Bool

    private var canSubmit: Bool {
        !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onCancel)

            VStack(alignment: .leading, spacing: 14) {
                Text("What would it mean about you if you failed?")
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                Text("Before this is sealed. Answer honestly — you'll be shown this again if you break it.")
                    .font(Typography.label)
                    .foregroundStyle(Theme.textMuted)

                TextField("It would mean...", text: $answer, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.red.opacity(0.45), lineWidth: 1)
                    )
                    .focused($isFocused)
                    .lineLimit(1...4)

                HStack {
                    Button("cancel", role: .cancel, action: onCancel)
                        .font(Typography.label)
                        .foregroundStyle(Theme.textMuted)
                        .buttonStyle(.plain)
                        .hoverScale()

                    Spacer()

                    Button("seal it") {
                        onSubmit(answer.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .font(Typography.subsectionTitle)
                    .foregroundStyle(canSubmit ? Color.white : Theme.textFaint)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(canSubmit ? Color.red.opacity(0.85) : Theme.fieldBackground)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                    .hoverScale()
                    .disabled(!canSubmit)
                }
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.6), radius: 40, y: 12)
            .onTapGesture {}
            .onAppear { isFocused = true }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}
