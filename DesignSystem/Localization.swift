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
        if let saved = UserDefaults.standard.string(forKey: "appLanguage") {
            self.current = AppLanguage(rawValue: saved) ?? .en
        } else {
            let systemLanguageCode = Locale.preferredLanguages.first
                .flatMap { Locale(identifier: $0).language.languageCode?.identifier }
            
            let detected: AppLanguage = systemLanguageCode == "pl" ? .pl : .en
            self.current = detected
            
            UserDefaults.standard.set(detected.rawValue, forKey: "appLanguage")
        }
    }
}

enum L10n {
    static var lang: AppLanguage { LanguageManager.shared.current }
}
