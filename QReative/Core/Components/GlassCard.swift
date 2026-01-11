import SwiftUI

// MARK: - GlassCard ViewModifier

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let backgroundOpacity: CGFloat
    let borderOpacity: CGFloat
    let borderWidth: CGFloat
    let useBlur: Bool

    init(
        cornerRadius: CGFloat = 20,
        backgroundOpacity: CGFloat = 0.05,
        borderOpacity: CGFloat = 0.06,
        borderWidth: CGFloat = 1,
        useBlur: Bool = true
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
                ZStack {
                    if useBlur {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                            .opacity(0.5)
                    }

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(backgroundOpacity))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(borderOpacity), lineWidth: borderWidth)
            }
    }
}

// MARK: - View Extension

extension View {
    /// Applies glassmorphism card style
    func glassCard(
        cornerRadius: CGFloat = 20,
        opacity: CGFloat = 0.05,
        borderOpacity: CGFloat = 0.06,
        useBlur: Bool = true
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

    /// Subtle glass effect for smaller elements
    func glassCardSubtle(cornerRadius: CGFloat = 12) -> some View {
        modifier(
            GlassCardModifier(
                cornerRadius: cornerRadius,
                backgroundOpacity: 0.03,
                borderOpacity: 0.04,
                useBlur: false
            )
        )
    }

    /// Prominent glass effect for highlighted cards
    func glassCardProminent(cornerRadius: CGFloat = 20) -> some View {
        modifier(
            GlassCardModifier(
                cornerRadius: cornerRadius,
                backgroundOpacity: 0.08,
                borderOpacity: 0.1,
                useBlur: true
            )
        )
    }
}

// MARK: - GlassCard Container View

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let opacity: CGFloat
    let padding: CGFloat
    let content: () -> Content

    init(
        cornerRadius: CGFloat = 20,
        opacity: CGFloat = 0.05,
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

// MARK: - Preview

#Preview {
    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: 20) {
            // Modifier kullanımı
            VStack(alignment: .leading, spacing: 8) {
                Text("Glass Card")
                    .typography(.headline)
                Text("Default modifier style")
                    .typography(.caption1, color: .textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glassCard()

            // Subtle variant
            HStack {
                Image(systemName: "qrcode")
                Text("Subtle Card")
                    .typography(.body)
            }
            .padding(12)
            .glassCardSubtle()

            // Prominent variant
            VStack(spacing: 8) {
                Text("PRO")
                    .typography(.headline)
                Text("Prominent style")
                    .typography(.caption1, color: .textSecondary)
            }
            .padding(16)
            .glassCardProminent()

            // Container view kullanımı
            GlassCard {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.warning)
                    Text("Container View Style")
                        .typography(.body)
                }
            }
        }
        .padding(20)
    }
}
