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
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            editingBadge

            section(label: L10n.JournalEditor.entrySectionLabel) {
                VStack(alignment: .leading, spacing: 0) {
                    TextField(L10n.JournalEditor.titlePlaceholder, text: $entry.title)
                        .textFieldStyle(.plain)
                        .font(Typography.title)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                        .focused($focusedField, equals: .title)
                        .onSubmit { focusedField = .content }
                        .onChange(of: entry.title) { scheduleSave() }

                    Rectangle().fill(Theme.border).frame(height: 0.5)

                    ZStack(alignment: .topLeading) {
                        if entry.content.isEmpty {
                            Text(L10n.JournalEditor.contentPlaceholder)
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
                            .onChange(of: entry.content) { scheduleSave() }
                    }
                    .frame(height: 280)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(dashedBorder(cornerRadius: 10))
                .onDisappear {
                    saveTask?.cancel()
                    try? modelContext.save()
                }
            }

            section(label: L10n.JournalEditor.moodSectionLabel) {
                MoodPicker(selection: Binding(
                    get: { entry.entryMood },
                    set: { entry.entryMood = $0 }
                ))
            }

            section(label: L10n.JournalEditor.tagsSectionLabel) {
                VStack(alignment: .leading, spacing: 8) {
                    if !entry.tags.isEmpty {
                        HStack {
                            ForEach(entry.tags.sorted(by: { $0.name < $1.name })) { tag in
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

                    TextField(L10n.JournalEditor.addTagPlaceholder, text: $newTagText)
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
            Text(L10n.JournalEditor.editingBadge)
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
        JournalEntryTag.deleteIfOrphaned(tag, modelContext: modelContext)
        try? modelContext.save()
    }
    
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            try? modelContext.save()
        }
    }
}

struct MoodPicker: View {
    @Binding var selection: Mood

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Mood.allCases, id: \.self) { mood in
                MoodOptionView(
                    mood: mood,
                    isSelected: selection == mood,
                    onTap: { selection = mood }
                )
            }
        }
    }
}

extension L10n {
    enum JournalEditor {
        static var entrySectionLabel: String {
            switch lang {
            case .en: return "entry"
            case .pl: return "wpis"
            }
        }

        static var moodSectionLabel: String {
            switch lang {
            case .en: return "mood"
            case .pl: return "nastrój"
            }
        }

        static var tagsSectionLabel: String {
            switch lang {
            case .en: return "tags"
            case .pl: return "tagi"
            }
        }

        static var editingBadge: String {
            switch lang {
            case .en: return "editing"
            case .pl: return "edycja"
            }
        }

        static var titlePlaceholder: String {
            switch lang {
            case .en: return "Title"
            case .pl: return "Tytuł"
            }
        }

        static var contentPlaceholder: String {
            switch lang {
            case .en: return "Write freely..."
            case .pl: return "Pisz swobodnie..."
            }
        }

        static var addTagPlaceholder: String {
            switch lang {
            case .en: return "Add tag"
            case .pl: return "Dodaj tag"
            }
        }
    }
}
