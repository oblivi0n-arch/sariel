enum SettingsCategory: CaseIterable, Hashable {
    case personalization
    case aiOllama
    case privacy
    case data
    case debug

    var icon: String {
        switch self {
        case .personalization: return "person"
        case .aiOllama: return "network"
        case .privacy: return "lock.shield"
        case .data: return "arrow.up.arrow.down.square"
        case .debug: return "ant"
        }
    }

    var title: String {
        switch self {
        case .personalization: return L10n.Settings.categoryPersonalization
        case .aiOllama: return L10n.Settings.categoryAIOllama
        case .privacy: return L10n.Settings.categoryPrivacy
        case .data: return L10n.Settings.categoryData
        case .debug: return L10n.Settings.categoryDebug
        }
    }
}
