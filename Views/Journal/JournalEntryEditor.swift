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
    @State private var measuredContentHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            editingBadge

            section(label: "entry") {
                VStack(alignment: .leading, spacing: 0) {
                    TextField("Title", text: $entry.title)
                        .textFieldStyle(.plain)
                        .font(Typography.title)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                        .focused($focusedField, equals: .title)
                        .onSubmit { focusedField = .content }

                    Rectangle().fill(Theme.border).frame(height: 0.5)

                    ZStack(alignment: .topLeading) {
                        if entry.content.isEmpty {
                            Text("Write freely...")
                                .font(Theme.uiFont)
                                .foregroundStyle(Theme.textFaint)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $entry.content)
                            .font(Theme.uiFont)
                            .foregroundStyle(Theme.textSecondary)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 9)
                            .padding(.top, 10)
                            .padding(.bottom, 7)
                            .focused($focusedField, equals: .content)
                    }
                    .frame(height: 280)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(dashedBorder(cornerRadius: 10))
            }

            section(label: "mood") {
                MoodPicker(selection: Binding(
                    get: { entry.entryMood },
                    set: { entry.entryMood = $0 }
                ))
            }

            section(label: "tags") {
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
                                .font(Typography.caption)
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
                        .font(Typography.label)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .overlay(dashedBorder(cornerRadius: 8))
                        .onSubmit(addTag)
                }
            }
        }
        .padding(16)
    }

    private var editingBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "pencil")
                .font(.system(size: 10, weight: .medium))
            Text("editing")
                .font(Typography.caption)
        }
        .foregroundStyle(Theme.textFaint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
    }

    private func section<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
                .textCase(.uppercase)
                .kerning(0.5)

            content()
        }
    }

    private func dashedBorder(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(Theme.border, style: StrokeStyle(lineWidth: 0.5, dash: [4, 3]))
    }
    
    private struct EntryHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
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
                MoodOption(
                    mood: mood,
                    isSelected: selection == mood,
                    onTap: { selection = mood }
                )
            }
        }
    }
}

