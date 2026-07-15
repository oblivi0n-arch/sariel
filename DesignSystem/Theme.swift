import SwiftUI

struct Theme {
    static let background = Color.black
    static let fieldBackground = Color(hex: "141416")

    static let border = Color.white.opacity(0.15)
    static let borderStrong = Color.white.opacity(0.35)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.75)
    static let textMuted = Color.white.opacity(0.45)
    static let textFaint = Color.white.opacity(0.28)

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
