import SwiftUI

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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

    /// Deep Matte Black - Primary background
    static let backgroundPrimary = Color(hex: "0F0F0F")

    /// Dark Grey - Secondary background
    static let backgroundSecondary = Color(hex: "1C1C1E")

    /// Card backgrounds
    static let backgroundTertiary = Color(hex: "2C2C2E")

    /// Glassmorphism background
    static let glassBg = Color.white.opacity(0.05)

    /// Glassmorphism border
    static let glassBorder = Color.white.opacity(0.1)

    // MARK: - Accents

    /// Electric Purple - Primary accent
    static let accentPrimary = Color(hex: "6200EA")

    /// Violet - Secondary accent
    static let accentSecondary = Color(hex: "9C27B0")

    /// Neon Cyan - Tertiary accent
    static let accentTertiary = Color(hex: "00E5FF")

    // MARK: - Text

    /// Primary text color
    static let textPrimary = Color.white

    /// Secondary text color
    static let textSecondary = Color.white.opacity(0.6)

    /// Tertiary text color
    static let textTertiary = Color.white.opacity(0.4)

    // MARK: - Semantic Colors

    /// Success state - Green
    static let success = Color(hex: "00E676")

    /// Danger state - Red
    static let danger = Color(hex: "FF3B30")

    /// Warning state - Gold
    static let warning = Color(hex: "FFD700")
}

// MARK: - QReative Gradients

extension LinearGradient {

    /// Purple to Violet gradient (135°)
    static let purpleGradient = LinearGradient(
        colors: [Color(hex: "6200EA"), Color(hex: "9C27B0")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Cyan gradient
    static let cyanGradient = LinearGradient(
        colors: [Color(hex: "00B8D4"), Color(hex: "00E5FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gold gradient
    static let goldGradient = LinearGradient(
        colors: [Color(hex: "FFD700"), Color(hex: "FFA000")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
