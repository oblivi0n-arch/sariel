import SwiftUI
import SwiftData

struct JournalEntryEditor: View {
    @Bindable var entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Title", text: $entry.title)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            MoodPicker(selection: Binding(
                get: { entry.entryMood },
                set: { entry.entryMood = $0 }
            ))

            TextField("Write freely...", text: $entry.content, axis: .vertical)
                .textFieldStyle(.plain)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(5...)
        }
        .padding(16)
    }
}

struct MoodPicker: View {
    @Binding var selection: Mood

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Mood.allCases, id: \.self) { mood in
                Image(systemName: mood.symbolName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(selection == mood ? Theme.textPrimary : Theme.textFaint)
                    .frame(width: 32, height: 32)
                    .background(selection == mood ? Theme.fieldBackground : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selection == mood ? Theme.border : .clear, lineWidth: 1)
                    )
                    .onTapGesture {
                        selection = mood
                    }
            }
        }
    }
}
