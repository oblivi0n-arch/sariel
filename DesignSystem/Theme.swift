import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case dark
    case light
    case starlight

    var baseColorScheme: ColorScheme {
        switch self {
        case .dark, .starlight: return .dark
        case .light: return .light
        }
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var current: AppTheme {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "appTheme")
        }
    }
    
    @Published var followSystem: Bool {
        didSet {
            UserDefaults.standard.set(followSystem, forKey: "appThemeFollowsSystem")
        }
    }
    
    @Published private(set) var systemColorScheme: ColorScheme = .dark
    
    var resolved: AppTheme {
        guard followSystem else { return current }
        return systemColorScheme == .dark ? .dark : .light
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.dark.rawValue
        self.current = AppTheme(rawValue: saved) ?? .dark
        self.followSystem = UserDefaults.standard.bool(forKey: "appThemeFollowsSystem")
    }
    
    func updateSystemColorScheme(_ scheme: ColorScheme) {
        guard systemColorScheme != scheme else { return }
        systemColorScheme = scheme
    }
}

struct Theme {
    private static var mode: AppTheme { ThemeManager.shared.resolved }
    private static let starlightGlow = Color(hex: "D6E4F0")
    
    static var background: Color {
        switch mode {
        case .dark: return Color.black
        case .light: return Color.white
        case .starlight: return Color(hex: "05070D")
        }
    }
    
    static var fieldBackground: Color {
        switch mode {
        case .dark: return Color(hex: "141416")
        case .light: return Color(hex: "F0F0F0")
        case .starlight: return Color(hex: "0D111C")
        }
    }
    
    static var border: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.15)
        case .light: return Color.black.opacity(0.15)
        case .starlight: return Color(hex: "3A4A66").opacity(0.4)
        }
    }
    
    static var borderStrong: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.35)
        case .light: return Color.black.opacity(0.35)
        case .starlight: return Color(hex: "5A7099").opacity(0.6)
        }
    }
    
    static var textPrimary: Color {
        switch mode {
        case .dark: return Color.white
        case .light: return Color.black
        case .starlight: return starlightGlow
        }
    }
    
    static var textSecondary: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.75)
        case .light: return Color.black.opacity(0.75)
        case .starlight: return starlightGlow.opacity(0.75)
        }
    }
    
    static var textMuted: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.45)
        case .light: return Color.black.opacity(0.45)
        case .starlight: return starlightGlow.opacity(0.45)
        }
    }
    
    static var textFaint: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.28)
        case .light: return Color.black.opacity(0.28)
        case .starlight: return starlightGlow.opacity(0.28)
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
