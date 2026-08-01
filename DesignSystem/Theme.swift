import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case dark
    case light
    case starlight
    case witness
    case ash
    case wildwood
    case rust

    var baseColorScheme: ColorScheme {
        switch self {
        case .dark, .starlight, .witness, .ash, .wildwood, .rust: return .dark
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
    private static let witnessGold = Color(hex: "E8D5A8")
    private static let ashLilac = Color(hex: "C4C0CC")
    private static let scalpelMint = Color(hex: "A8D4C0")
    private static let rustClay = Color(hex: "D4917A")

    private static let witnessBorder = Color(hex: "5A4A30")
    private static let ashBorder = Color(hex: "3A3A45")
    private static let scalpelBorder = Color(hex: "2E4A40")
    private static let rustBorder = Color(hex: "5A3020")
    
    static var background: Color {
        switch mode {
        case .dark: return Color.black
        case .light: return Color.white
        case .starlight: return Color(hex: "05070D")
        case .witness: return Color(hex: "14100A")
        case .ash: return Color(hex: "0E0E12")
        case .wildwood: return Color(hex: "0A1210")
        case .rust: return Color(hex: "150A08")
        }
    }

    static var fieldBackground: Color {
        switch mode {
        case .dark: return Color(hex: "141416")
        case .light: return Color(hex: "F0F0F0")
        case .starlight: return Color(hex: "0D111C")
        case .witness: return Color(hex: "1E1810")
        case .ash: return Color(hex: "17171D")
        case .wildwood: return Color(hex: "111C18")
        case .rust: return Color(hex: "1F1210")
        }
    }

    static var border: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.15)
        case .light: return Color.black.opacity(0.15)
        case .starlight: return Color(hex: "3A4A66").opacity(0.4)
        case .witness: return witnessBorder.opacity(0.4)
        case .ash: return ashBorder.opacity(0.4)
        case .wildwood: return scalpelBorder.opacity(0.4)
        case .rust: return rustBorder.opacity(0.4)
        }
    }

    static var borderStrong: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.35)
        case .light: return Color.black.opacity(0.35)
        case .starlight: return Color(hex: "5A7099").opacity(0.6)
        case .witness: return witnessBorder.opacity(0.6)
        case .ash: return ashBorder.opacity(0.6)
        case .wildwood: return scalpelBorder.opacity(0.6)
        case .rust: return rustBorder.opacity(0.6)
        }
    }

    static var textPrimary: Color {
        switch mode {
        case .dark: return Color.white
        case .light: return Color.black
        case .starlight: return starlightGlow
        case .witness: return witnessGold
        case .ash: return ashLilac
        case .wildwood: return scalpelMint
        case .rust: return rustClay
        }
    }

    static var textSecondary: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.75)
        case .light: return Color.black.opacity(0.75)
        case .starlight: return starlightGlow.opacity(0.75)
        case .witness: return witnessGold.opacity(0.75)
        case .ash: return ashLilac.opacity(0.75)
        case .wildwood: return scalpelMint.opacity(0.75)
        case .rust: return rustClay.opacity(0.75)
        }
    }

    static var textMuted: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.45)
        case .light: return Color.black.opacity(0.45)
        case .starlight: return starlightGlow.opacity(0.45)
        case .witness: return witnessGold.opacity(0.45)
        case .ash: return ashLilac.opacity(0.45)
        case .wildwood: return scalpelMint.opacity(0.45)
        case .rust: return rustClay.opacity(0.45)
        }
    }

    static var textFaint: Color {
        switch mode {
        case .dark: return Color.white.opacity(0.28)
        case .light: return Color.black.opacity(0.28)
        case .starlight: return starlightGlow.opacity(0.28)
        case .witness: return witnessGold.opacity(0.28)
        case .ash: return ashLilac.opacity(0.28)
        case .wildwood: return scalpelMint.opacity(0.28)
        case .rust: return rustClay.opacity(0.28)
        }
    }

    static var tribunalAccent: Color {
        switch mode {
        case .dark, .light: return .red
        case .starlight: return Color(hex: "5EEAF0")
        case .witness: return Color(hex: "6B3410")
        case .ash: return Color(hex: "B08FD8")
        case .wildwood: return Color(hex: "2F6844")
        case .rust: return Color(hex: "D9601A")
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
