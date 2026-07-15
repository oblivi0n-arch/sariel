import SwiftUI
import SwiftData

private enum Field {
    case title
    case content
}

struct JournalEntryEditor: View {
    @Bindable var entry: JournalEntry
    @FocusState private var focusedField: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MoodPicker(selection: Binding(
                get: { entry.entryMood },
                set: { entry.entryMood = $0 }
            ))

            TextField("Title", text: $entry.title)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .focused($focusedField, equals: .title)
                .onSubmit {
                    focusedField = .content
                }

            ZStack(alignment: .topLeading) {
                if entry.content.isEmpty {
                    Text("Write freely...")
                        .font(Theme.uiFont)
                        .foregroundStyle(Theme.textFaint)
                        .padding(.top, 1)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $entry.content)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textSecondary)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .focused($focusedField, equals: .content)
            }
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
