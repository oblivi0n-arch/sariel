import SwiftUI

struct Theme {
    static let background = Color(hex: "0A0A0C")
    static let surface = Color(hex: "141416")
    static let surfaceElevated = Color(hex: "1B1B1E")
    static let border = Color(hex: "232326")

    static let accent = Color(hex: "2A2A2D")
    static let accentBright = Color(hex: "E5E5E5")

    static let textPrimary = Color(hex: "D8D5CE")
    static let textSecondary = Color(hex: "B9B7B1")
    static let textMuted = Color(hex: "7A7A7E")
    static let textFaint = Color(hex: "5C5C60")

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
