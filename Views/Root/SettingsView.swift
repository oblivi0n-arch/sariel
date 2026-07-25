import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var connectionMonitor: ConnectionMonitor
    @Binding var isPresented: Bool
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var languageManager = LanguageManager.shared

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("isPostReset") var isPostReset: Bool = false
    @AppStorage("ollamaHost") var host: String = OllamaDefaults.host
    @AppStorage("ollamaModel") var model: String = OllamaDefaults.model
    @AppStorage("useJournalContext") var useJournalContext: Bool = false
    @AppStorage("useCredibilityContext") var useCredibilityContext: Bool = false
    @AppStorage("autoStartOllama") var autoStartOllama: Bool = false
    @AppStorage("ollamaExecutablePath") var ollamaExecutablePath: String = ""
    @AppStorage("username") var username: String = ""
    @AppStorage(ShortcutAction.dashboard.storageKey) var dashboardShortcut = ShortcutAction.dashboard.defaultShortcut
    @AppStorage(ShortcutAction.chat.storageKey) var chatShortcut = ShortcutAction.chat.defaultShortcut
    @AppStorage(ShortcutAction.journal.storageKey) var journalShortcut = ShortcutAction.journal.defaultShortcut
    @AppStorage(ShortcutAction.tribunal.storageKey) var tribunalShortcut = ShortcutAction.tribunal.defaultShortcut

    @State var isManualPathShown = false
    @State var availableModels: [String] = []
    @State var isLoadingModels = false
    @State var modelsLoadError: String?
    @State var showResetConfirmation = false
    #if DEBUG
    @State var devTapCount = 0
    @State var isDevModeUnlocked = false
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    identitySection
                    appearanceSection
                    languageSection

                    Divider().overlay(Theme.border)

                    ollamaSection
                    contextSection
                    credibilitySection

                    Divider().overlay(Theme.border)

                    keyboardShortcutsSection

                    Divider().overlay(Theme.border)

                    dangerZone
                    #if DEBUG
                    if isDevModeUnlocked {
                        debugOnboardingSection
                    }
                    #endif
                }
                .padding(20)
            }

            versionFooter
        }
        .background(Theme.background)
        .overlay { resetConfirmationOverlayContent }
        .task {
            await fetchAvailableModels()
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .font(Typography.icon)
                .foregroundStyle(Theme.textMuted)

            Text(L10n.Settings.title)
                .font(Typography.title)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(Typography.iconButton)
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 24, height: 24)
                    .background(Theme.fieldBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.border).frame(height: 0.5)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private var versionFooter: some View {
        Text(L10n.Settings.versionFooter(version: appVersion, handle: "@oblivi0n-arch"))
            .font(Typography.caption)
            .foregroundStyle(Theme.textFaint)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 10)
            #if DEBUG
            .onTapGesture {
                devTapCount += 1
                if devTapCount == 5 {
                    isDevModeUnlocked = true
                }
            }
            #endif
    }

    func sectionHeader<Accessory: View>(
        icon: String,
        title: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(Typography.caption)
            }
            .foregroundStyle(Theme.textFaint)

            Spacer()

            accessory()
        }
    }
}

extension L10n {
    enum Settings {
        static var title: String {
            switch lang {
            case .en: return "settings"
            case .pl: return "ustawienia"
            }
        }

        static func versionFooter(version: String, handle: String) -> String {
            switch lang {
            case .en: return "v\(version) · built by \(handle)"
            case .pl: return "v\(version) · stworzone przez \(handle)"
            }
        }
    }
}
