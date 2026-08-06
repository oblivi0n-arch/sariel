import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var connectionMonitor: ConnectionMonitor
    @Binding var isPresented: Bool
    var onStartAcquaintance: () -> Void
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
    @AppStorage("aboutMe") var aboutMe: String = ""
    @AppStorage("hasStartedAcquaintance") var hasStartedAcquaintance: Bool = false
    @AppStorage("journalStyle") var journalStyle: JournalStyle = .conciseFactual
    @AppStorage("autoDeleteEnabled") var autoDeleteEnabled: Bool = false
    @AppStorage("autoDeleteThresholdDays") var autoDeleteThresholdDays: Int = AppLimits.autoDeleteThresholdOptions[0]
    @AppStorage("appLockEnabled") var appLockEnabled: Bool = false
    @AppStorage("appLockUseBiometrics") var appLockUseBiometrics: Bool = true
    @AppStorage(ShortcutAction.dashboard.storageKey) var dashboardShortcut = ShortcutAction.dashboard.defaultShortcut
    @AppStorage(ShortcutAction.chat.storageKey) var chatShortcut = ShortcutAction.chat.defaultShortcut
    @AppStorage(ShortcutAction.journal.storageKey) var journalShortcut = ShortcutAction.journal.defaultShortcut
    @AppStorage(ShortcutAction.tribunal.storageKey) var tribunalShortcut = ShortcutAction.tribunal.defaultShortcut
    @AppStorage(ShortcutAction.meditation.storageKey) var meditationShortcut = ShortcutAction.meditation.defaultShortcut
    
    @State private var selectedCategory: SettingsCategory = .personalization
    @State var isManualPathShown = false
    @State var availableModels: [String] = []
    @State var isLoadingModels = false
    @State var modelsLoadError: String?
    @State var showResetConfirmation = false
    @State var showImportConfirmation = false
    @State var pendingImportURL: URL?
    @State var dataTransferAlert: DataTransferAlert?
    @FocusState var isUsernameFieldFocused: Bool
    @State var draftUsername: String = ""
    @State var isPinSetupShown = false
    @State var hasPinSet = false
    @State var pendingPinAction: PendingPinAction?
#if DEBUG
    @State var devTapCount = 0
    @State var isDevModeUnlocked = false
#endif
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            categoryTabBar
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    categoryContent
                }
                .padding(20)
                .id(selectedCategory)
                .transition(.opacity)
            }
            
            versionFooter
        }
        .background(Theme.background)
        .overlay { resetConfirmationOverlayContent }
        .overlay { pinVerificationOverlayContent }
        .overlay { pinSetupOverlayContent }
        .task {
            draftUsername = username
            hasPinSet = PinKeychainStore.hasPinSet()
            await fetchAvailableModels()
        }
    }
    
    @ViewBuilder
    private var categoryContent: some View {
        switch selectedCategory {
        case .personalization:
            identitySection
            aboutMeSection
            appearanceSection
            languageSection
            keyboardShortcutsSection
        case .aiOllama:
            ollamaSection
            contextSection
            credibilitySection
            journalStyleSection
        case .privacy:
            privacySection
        case .data:
            dataTransferSection
            dangerZone
        case .debug:
#if DEBUG
            debugOnboardingSection
#else
            EmptyView()
#endif
        }
    }
    
    private var categoryTabBar: some View {
        HStack(spacing: 4) {
            Image(systemName: "gearshape")
                .font(Typography.icon)
                .foregroundStyle(Theme.textMuted)
                .padding(.trailing, 6)
            
            Spacer()
            
            ForEach(visibleCategories, id: \.self) { category in
                SettingsCategoryTabButton(
                    category: category,
                    isSelected: selectedCategory == category,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                )
            }
            
            Spacer()
            
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(Typography.iconButton)
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                    .hoverBorder(Circle())
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.border).frame(height: 0.5)
        }
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
    
    private var visibleCategories: [SettingsCategory] {
        var categories = SettingsCategory.allCases.filter { $0 != .debug }
#if DEBUG
        if isDevModeUnlocked {
            categories.append(.debug)
        }
#endif
        return categories
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
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDevModeUnlocked = true
                        selectedCategory = .debug
                    }
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
    
    func commitUsername() {
        username = draftUsername
    }
    
    func handleAcquaintanceLinkTap() {
        isPresented = false
        onStartAcquaintance()
    }
    
#if DEBUG
    var debugOnboardingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "ant", title: "DEBUG") {
                EmptyView()
            }
            
            HStack(spacing: 10) {
                Button("Force onboarding") {
                    isPostReset = false
                    hasCompletedOnboarding = false
                }
                Button("Force onboarding (post-reset)") {
                    isPostReset = true
                    hasCompletedOnboarding = false
                }
            }
            .font(Typography.caption)
            .buttonStyle(.plain)
            .foregroundStyle(Theme.textMuted)
            
            Button("Backdate pending commitments (unlock Tribunal)") {
                backdatePendingCommitments()
            }
            .font(Typography.caption)
            .buttonStyle(.plain)
            .foregroundStyle(Theme.textMuted)
            
            Button("Backdate sealed self-letters (make available)") {
                backdateSealedLetters()
            }
            .font(Typography.caption)
            .buttonStyle(.plain)
            .foregroundStyle(Theme.textMuted)
            
            Button("Reset data (skip onboarding)") {
                resetEverything(skipOnboarding: true)
            }
            .font(Typography.caption)
            .buttonStyle(.plain)
            .foregroundStyle(Theme.textMuted)
        }
    }
    
    private func backdatePendingCommitments() {
        let descriptor = FetchDescriptor<Commitment>(
            predicate: #Predicate<Commitment> { $0.status == "pending" }
        )
        guard let pending = try? modelContext.fetch(descriptor) else { return }
        for commitment in pending {
            commitment.createdAt = Date().addingTimeInterval(-8 * 24 * 60 * 60)
        }
        try? modelContext.save()
    }
    
    private func backdateSealedLetters() {
        let descriptor = FetchDescriptor<SelfLetter>()
        guard let letters = try? modelContext.fetch(descriptor) else { return }
        
        for letter in letters where letter.letterStatus == .sealed {
            letter.openDate = Date().addingTimeInterval(-60)
        }
        try? modelContext.save()
        
        SelfLetterService.refreshAvailability(context: modelContext)
    }
#endif
}

private struct SettingsCategoryTabButton: View {
    let category: SettingsCategory
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(Typography.label)
                Text(category.title)
                    .font(Typography.label)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .trackHover($isHovering)
    }

    private var foregroundColor: Color {
        if isSelected { return Theme.textPrimary }
        if isHovering { return Theme.textMuted }
        return Theme.textFaint
    }

    private var borderColor: Color {
        if isSelected { return Theme.borderStrong }
        if isHovering { return Theme.border }
        return .clear
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
        
        static var categoryPersonalization: String {
            switch lang {
            case .en: return "personalization"
            case .pl: return "personalizacja"
            }
        }
        
        static var categoryAIOllama: String {
            switch lang {
            case .en: return "AI"
            case .pl: return "AI"
            }
        }
        
        static var categoryPrivacy: String {
            switch lang {
            case .en: return "privacy"
            case .pl: return "prywatność"
            }
        }
        
        static var categoryData: String {
            switch lang {
            case .en: return "data"
            case .pl: return "dane"
            }
        }
        
        static var categoryDebug: String {
            "debug"
        }
    }
}
