import SwiftUI
import SwiftData

struct SelfLetterArchiveView: View {
    let letters: [SelfLetter]
    let onBack: () -> Void

    @State private var activeLetter: SelfLetter?
    @State private var searchText: String = ""
    @State private var isSearchExpanded = false
    @State private var isSearchHovering = false
    @FocusState private var isSearchFocused: Bool

    private var sortedLetters: [SelfLetter] {
        letters.sorted { ($0.openedAt ?? .distantPast) > ($1.openedAt ?? .distantPast) }
    }

    private var filteredLetters: [SelfLetter] {
        guard !searchText.isEmpty else { return sortedLetters }
        return sortedLetters.filter {
            ($0.title ?? "").localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                header

                if let activeLetter {
                    detail(for: activeLetter)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(filteredLetters) { letter in
                                SelfLetterArchiveRow(letter: letter, searchText: searchText, onSelect: { activeLetter = letter })
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: activeLetter == nil ? onBack : { activeLetter = nil }) {
                Image(systemName: "chevron.left")
                    .font(Typography.iconButton)
                    .foregroundStyle(Theme.textMuted)
            }
            .buttonStyle(.plain)

            if activeLetter == nil, isSearchExpanded {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textFaint)

                    PlaceholderTextField(
                        placeholder: L10n.SelfLetterArchive.searchPlaceholder,
                        text: $searchText,
                        font: Typography.label,
                        textColor: Theme.textSecondary
                    )
                        .focused($isSearchFocused)

                    Button(action: collapseSearch) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.fieldBackground)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
            } else {
                Text(L10n.SelfLetterArchive.title)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                if activeLetter == nil {
                    Button(action: expandSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(Typography.iconButton)
                            .foregroundStyle(Theme.textMuted)
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isSearchHovering ? Theme.border : .clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isSearchHovering = hovering
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearchExpanded)
    }

    private func expandSearch() {
        isSearchExpanded = true
        isSearchFocused = true
    }

    private func collapseSearch() {
        searchText = ""
        isSearchExpanded = false
        isSearchFocused = false
    }

    private func detail(for letter: SelfLetter) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let title = letter.title, !title.isEmpty {
                    Text(title)
                        .font(Typography.sectionTitle)
                        .foregroundStyle(Theme.textPrimary)
                }

                Text(letter.content)
                    .font(Theme.voiceFont)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let openedAt = letter.openedAt {
                    HStack(spacing: 4) {
                        Text(L10n.SelfLetterReveal.writtenOnLabel)
                        Text(letter.createdAt, style: .date)
                        Text("·")
                        Text(L10n.SelfLetterArchive.openedOnLabel)
                        Text(openedAt, style: .date)
                    }
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
                }
            }
        }
    }
}

extension L10n {
    enum SelfLetterArchive {
        static var title: String {
            switch lang {
            case .en: return "Sealed letters"
            case .pl: return "Zapieczętowane listy"
            }
        }

        static var untitled: String {
            switch lang {
            case .en: return "Untitled letter"
            case .pl: return "List bez tytułu"
            }
        }

        static var openedOnLabel: String {
            switch lang {
            case .en: return "opened on"
            case .pl: return "otwarto"
            }
        }

        static var entryPointLabel: String {
            switch lang {
            case .en: return "view sealed letters"
            case .pl: return "zobacz zapieczętowane listy"
            }
        }

        static var searchPlaceholder: String {
            switch lang {
            case .en: return "Search letters"
            case .pl: return "Szukaj listów"
            }
        }
    }
}
