import SwiftUI

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - QReative Color Palette
extension Color {

    // MARK: - Backgrounds
    static let backgroundPrimary = Color(hex: "0F0F0F")

    static let backgroundSecondary = Color(hex: "1C1C1E")

    static let backgroundTertiary = Color(hex: "2C2C2E")

    static let glassBg = Color.white.opacity(0.05)

    static let glassBorder = Color.white.opacity(0.1)

    // MARK: - Accents
    static let accentPrimary = Color(hex: "6200EA")

    static let accentSecondary = Color(hex: "9C27B0")

    static let accentTertiary = Color(hex: "00E5FF")

    // MARK: - Text
    static let textPrimary = Color.white

    static let textSecondary = Color.white.opacity(0.6)

    static let textTertiary = Color.white.opacity(0.4)

    // MARK: - Semantic Colors
    static let success = Color(hex: "00E676")

    static let danger = Color(hex: "FF3B30")

    static let warning = Color(hex: "FFD700")
}

// MARK: - QReative Gradients
extension LinearGradient {

    static let purpleGradient = LinearGradient(
        colors: [Color(hex: "6200EA"), Color(hex: "9C27B0")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cyanGradient = LinearGradient(
        colors: [Color(hex: "00B8D4"), Color(hex: "00E5FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [Color(hex: "FFD700"), Color(hex: "FFA000")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
