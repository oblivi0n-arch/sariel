import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case dark
    case light
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var current: AppTheme {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "appTheme")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.dark.rawValue
        self.current = AppTheme(rawValue: saved) ?? .dark
    }
}

struct Theme {
    private static var mode: AppTheme { ThemeManager.shared.current }

    static var background: Color {
        switch mode {
        case .dark: return Color.black
        case .light: return Color.white
        }
    }

    static var fieldBackground: Color {
        switch mode {
        case .dark: return Color(hex: "141416")
        case .light: return Color(hex: "F0F0F0")
        }
    }

    static var border: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.15)
        case .light: return Color.black.opacity(0.15)
        }
    }

    static var borderStrong: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.35)
        case .light: return Color.black.opacity(0.35)
        }
    }

    static var textPrimary: Color {
        switch mode {
        case .dark: return Color.white
        case .light: return Color.black
        }
    }

    static var textSecondary: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.75)
        case .light: return Color.black.opacity(0.75)
        }
    }

    static var textMuted: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.45)
        case .light: return Color.black.opacity(0.45)
        }
    }

    static var textFaint: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.28)
        case .light: return Color.black.opacity(0.28)
        }
    }

    static let voiceFont = Font.system(.body, design: .serif)
    static let uiFont = Font.system(.body, design: .default)
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255
        let b = Double(rgbValue & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b)
    }
}
