import SwiftUI
import AppKit

struct LaunchFailureView: View {
    let message: String

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "externaldrive.badge.xmark")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.textMuted)

                VStack(spacing: 8) {
                    Text(L10n.LaunchFailure.title)
                        .font(Typography.subsectionTitle)
                        .foregroundStyle(Theme.textPrimary)

                    Text(L10n.LaunchFailure.explanation)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 380)
                }

                if !message.isEmpty {
                    Text(message)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)
                        .frame(maxWidth: 380)
                }

                HStack(spacing: 10) {
                    Button(L10n.LaunchFailure.revealInFinder, action: revealStoreDirectory)
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.textSecondary)

                    Button(L10n.LaunchFailure.quit) {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textSecondary)
                }
                .font(Typography.label)
            }
            .padding(40)
        }
    }

    private func revealStoreDirectory() {
        NSWorkspace.shared.open(URL.applicationSupportDirectory)
    }
}

extension L10n {
    enum LaunchFailure {
        static var title: String {
            switch L10n.lang {
            case .en: return "Couldn't open your data"
            case .pl: return "Nie udało się otworzyć Twoich danych"
            }
        }

        static var explanation: String {
            switch L10n.lang {
            case .en: return "The local database couldn't be loaded. Your data hasn't been deleted — the file is still on this device. If you have an export, you can move the store file aside and import it after restarting."
            case .pl: return "Nie udało się wczytać lokalnej bazy danych. Twoje dane nie zostały usunięte — plik nadal jest na tym urządzeniu. Jeśli masz plik eksportu, możesz odsunąć plik bazy i zaimportować dane po ponownym uruchomieniu."
            }
        }

        static var revealInFinder: String {
            switch L10n.lang {
            case .en: return "Show in Finder"
            case .pl: return "Pokaż w Finderze"
            }
        }

        static var quit: String {
            switch L10n.lang {
            case .en: return "Quit"
            case .pl: return "Zakończ"
            }
        }
    }
}
