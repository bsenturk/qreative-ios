import SwiftUI

// MARK: - Typography Style

enum Typography {
    case largeTitle   // 32pt, bold
    case title1       // 28pt, bold
    case title2       // 22pt, semibold
    case title3       // 17pt, semibold
    case headline     // 17pt, semibold
    case body         // 15pt, regular
    case callout      // 14pt, regular
    case caption1     // 13pt, regular
    case caption2     // 12pt, regular
    case footnote     // 11pt, regular

    var font: Font {
        switch self {
        case .largeTitle:
            return .system(size: 32, weight: .bold)
        case .title1:
            return .system(size: 28, weight: .bold)
        case .title2:
            return .system(size: 22, weight: .semibold)
        case .title3:
            return .system(size: 17, weight: .semibold)
        case .headline:
            return .system(size: 17, weight: .semibold)
        case .body:
            return .system(size: 15, weight: .regular)
        case .callout:
            return .system(size: 14, weight: .regular)
        case .caption1:
            return .system(size: 13, weight: .regular)
        case .caption2:
            return .system(size: 12, weight: .regular)
        case .footnote:
            return .system(size: 11, weight: .regular)
        }
    }

    var lineSpacing: CGFloat {
        switch self {
        case .largeTitle, .title1:
            return 4
        case .title2, .title3, .headline:
            return 3
        case .body, .callout:
            return 2
        case .caption1, .caption2, .footnote:
            return 1
        }
    }
}

// MARK: - Typography ViewModifier

struct TypographyModifier: ViewModifier {
    let style: Typography
    var color: Color = .textPrimary

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .lineSpacing(style.lineSpacing)
            .foregroundStyle(color)
    }
}

// MARK: - View Extension

extension View {
    func typography(_ style: Typography, color: Color = .textPrimary) -> some View {
        modifier(TypographyModifier(style: style, color: color))
    }
}
