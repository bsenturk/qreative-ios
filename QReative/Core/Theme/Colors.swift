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

// MARK: - QReative Color Palette (Warm Light Theme)
extension Color {

    // MARK: - Backgrounds & Surfaces
    static let backgroundPrimary = Color(hex: "FFFFFF")   // white paper
    static let backgroundSecondary = Color(hex: "FFFFFF") // white
    static let backgroundTertiary = Color(hex: "ECE7DD")  // line/divider
    static let surface = Color(hex: "FFFFFF")             // white card surface
    static let surface2 = Color(hex: "F2F2F4")           // neutral light gray fill

    // MARK: - Card & Border
    static let glassBg = Color(hex: "FFFFFF")
    static let glassBorder = Color(hex: "ECE7DD")
    static let lineColor = Color(hex: "ECE7DD")
    static let lineStrong = Color(hex: "DAD3C6")

    // MARK: - Accents
    static let accentPrimary = Color(hex: "3457C8")       // cobalt blue (brand)
    static let accentSecondary = Color(hex: "2742A6")     // deeper cobalt
    static let accentTertiary = Color(hex: "5B7AE0")      // light cobalt
    static let accentSoft = Color(hex: "3457C8").opacity(0.13)

    // MARK: - Text / Ink
    static let textPrimary = Color(hex: "1A1814")         // warm near-black
    static let textSecondary = Color(hex: "6B655B")       // warm mid-grey
    static let textTertiary = Color(hex: "A8A192")        // warm muted
    static let ink = Color(hex: "1A1814")
    static let ink2 = Color(hex: "6B655B")
    static let ink3 = Color(hex: "A8A192")

    // MARK: - Semantic Colors
    static let success = Color(hex: "2F6B4F")             // forest green
    static let danger = Color(hex: "C0392B")              // warm red
    static let warning = Color(hex: "F0A500")             // amber
}

