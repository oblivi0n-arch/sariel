import SwiftUI

struct MoodPromptOverlay: View {
    let onSelect: (Mood) -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onCancel)

            VStack(spacing: 16) {
                Text("How are you feeling?")
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 10) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        MoodOption(mood: mood, isSelected: false, onTap: { onSelect(mood) })
                    }
                }
            }
            .padding(24)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.6), radius: 40, y: 12)
            .onTapGesture {}
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}
