import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable {
    case en
    case pl
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "appLanguage")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.en.rawValue
        self.current = AppLanguage(rawValue: saved) ?? .en
    }
}

enum L10n {
    static var lang: AppLanguage { LanguageManager.shared.current }
}
