import SwiftUI

// MARK: - Warm Card ViewModifier
// Replaces the former glass/blur style with a warm white card + border + subtle shadow
struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let backgroundOpacity: CGFloat
    let borderOpacity: CGFloat
    let borderWidth: CGFloat
    let useBlur: Bool

    init(
        cornerRadius: CGFloat = 22,
        backgroundOpacity: CGFloat = 1.0,
        borderOpacity: CGFloat = 1.0,
        borderWidth: CGFloat = 1,
        useBlur: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.backgroundOpacity = backgroundOpacity
        self.borderOpacity = borderOpacity
        self.borderWidth = borderWidth
        self.useBlur = useBlur
    }

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.surface.opacity(backgroundOpacity))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.lineColor.opacity(borderOpacity), lineWidth: borderWidth)
            }
            .shadow(color: Color.ink.opacity(0.04), radius: 2, x: 0, y: 1)
            .shadow(color: Color.ink.opacity(0.10), radius: 24, x: 0, y: 8)
    }
}

// MARK: - View Extension
extension View {
    func glassCard(
        cornerRadius: CGFloat = 22,
        opacity: CGFloat = 1.0,
        borderOpacity: CGFloat = 1.0,
        useBlur: Bool = false
    ) -> some View {
        modifier(
            GlassCardModifier(
                cornerRadius: cornerRadius,
                backgroundOpacity: opacity,
                borderOpacity: borderOpacity,
                useBlur: useBlur
            )
        )
    }

    // Subtle variant: used for small inline elements
    func glassCardSubtle(cornerRadius: CGFloat = 12) -> some View {
        modifier(
            GlassCardModifier(
                cornerRadius: cornerRadius,
                backgroundOpacity: 1.0,
                borderOpacity: 1.0,
                borderWidth: 1,
                useBlur: false
            )
        )
    }

    func glassCardProminent(cornerRadius: CGFloat = 22) -> some View {
        modifier(
            GlassCardModifier(
                cornerRadius: cornerRadius,
                backgroundOpacity: 1.0,
                borderOpacity: 1.0,
                borderWidth: 1,
                useBlur: false
            )
        )
    }

    // Dark variant: for items placed on dark backgrounds (e.g. camera screen)
    func darkCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.12))
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
    }
}

// MARK: - GlassCard Container View
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let opacity: CGFloat
    let padding: CGFloat
    let content: () -> Content

    init(
        cornerRadius: CGFloat = 22,
        opacity: CGFloat = 1.0,
        padding: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .glassCard(cornerRadius: cornerRadius, opacity: opacity)
    }
}
