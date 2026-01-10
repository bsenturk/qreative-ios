import SwiftUI

// MARK: - Spacing

struct Spacing {
    let xxs: CGFloat = 4
    let xs: CGFloat = 8
    let sm: CGFloat = 12
    let md: CGFloat = 16
    let lg: CGFloat = 20
    let xl: CGFloat = 24
    let xxl: CGFloat = 32
    let xxxl: CGFloat = 40

    /// Screen edge padding
    let screen: CGFloat = 20

    /// Card internal padding
    let card: CGFloat = 16

    /// Section spacing
    let section: CGFloat = 24
}

// MARK: - Corner Radius

struct CornerRadius {
    let xs: CGFloat = 4
    let small: CGFloat = 8
    let medium: CGFloat = 12
    let large: CGFloat = 16
    let xl: CGFloat = 20
    let xxl: CGFloat = 24

    /// Cards
    let card: CGFloat = 20

    /// Buttons
    let button: CGFloat = 16

    /// Small elements (tags, badges)
    let element: CGFloat = 12
}

// MARK: - Animation Presets

struct AnimationPresets {
    /// Default spring animation
    let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)

    /// Quick spring for micro-interactions
    let springQuick = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Bouncy spring for playful feedback
    let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// Smooth ease out
    let easeOut = Animation.easeOut(duration: 0.25)

    /// Smooth ease in out
    let easeInOut = Animation.easeInOut(duration: 0.3)

    /// Quick fade
    let fade = Animation.easeOut(duration: 0.15)

    /// Slow reveal
    let reveal = Animation.easeOut(duration: 0.4)

    /// Page transition
    let page = Animation.spring(response: 0.45, dampingFraction: 0.85)
}

// MARK: - Theme

struct Theme {
    let spacing = Spacing()
    let radius = CornerRadius()
    let animation = AnimationPresets()

    // Static access to singleton
    static let shared = Theme()

    private init() {}
}

// MARK: - Environment Key

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.shared
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    func themed() -> some View {
        environment(\.theme, Theme.shared)
    }
}

// MARK: - Convenience Accessors

extension Theme {
    /// Quick access to spacing values
    static var spacing: Spacing { shared.spacing }

    /// Quick access to corner radius values
    static var radius: CornerRadius { shared.radius }

    /// Quick access to animation presets
    static var animation: AnimationPresets { shared.animation }
}
