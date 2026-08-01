import SwiftUI
import SwiftData

struct SelfLetterArchiveView: View {
    let letters: [SelfLetter]
    let onBack: () -> Void

    @State private var activeLetter: SelfLetter?

    private var sortedLetters: [SelfLetter] {
        letters.sorted { ($0.openedAt ?? .distantPast) > ($1.openedAt ?? .distantPast) }
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
                            ForEach(sortedLetters) { letter in
                                SelfLetterArchiveRow(letter: letter, onSelect: { activeLetter = letter })
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

            Text(L10n.SelfLetterArchive.title)
                .font(Typography.title)
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func detail(for letter: SelfLetter) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
    }
}
