import SwiftUI
import SwiftData

private enum Field {
    case title
    case content
}

struct JournalEntryEditor: View {
    @Bindable var entry: JournalEntry
    @FocusState private var focusedField: Field?
    @Environment(\.modelContext) private var modelContext
    @Query private var allTags: [JournalEntryTag]
    @State private var newTagText: String = ""

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
            
            VStack(alignment: .leading, spacing: 8) {
                if !entry.tags.isEmpty {
                    HStack {
                        ForEach(entry.tags) { tag in
                            HStack(spacing: 4) {
                                Text("#\(tag.name)")
                                Button(action: { removeTag(tag) }) {
                                    Image(systemName: "xmark")
                                }
                                .buttonStyle(.plain)
                            }
                            .font(.system(size: 11))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(Theme.textMuted)
                        }
                    }
                }

                TextField("Add tag", text: $newTagText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .onSubmit(addTag)
            }
        }
        .padding(16)
    }
    
    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !entry.tags.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            newTagText = ""
            return
        }
        if let existing = allTags.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            entry.tags.append(existing)
        } else {
            let tag = JournalEntryTag(name: trimmed)
            modelContext.insert(tag)
            entry.tags.append(tag)
        }
        newTagText = ""
        try? modelContext.save()
    }

    private func removeTag(_ tag: JournalEntryTag) {
        entry.tags.removeAll { $0.id == tag.id }
        try? modelContext.save()
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


