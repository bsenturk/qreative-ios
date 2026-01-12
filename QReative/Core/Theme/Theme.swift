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

    let screen: CGFloat = 20

    let card: CGFloat = 16

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

    let card: CGFloat = 20

    let button: CGFloat = 16

    let element: CGFloat = 12
}

// MARK: - Animation Presets
struct AnimationPresets {
    let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)

    let springQuick = Animation.spring(response: 0.3, dampingFraction: 0.7)

    let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)

    let easeOut = Animation.easeOut(duration: 0.25)

    let easeInOut = Animation.easeInOut(duration: 0.3)

    let fade = Animation.easeOut(duration: 0.15)

    let reveal = Animation.easeOut(duration: 0.4)

    let page = Animation.spring(response: 0.45, dampingFraction: 0.85)
}

// MARK: - Theme
struct Theme {
    let spacing = Spacing()
    let radius = CornerRadius()
    let animation = AnimationPresets()

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
    static var spacing: Spacing { shared.spacing }

    static var radius: CornerRadius { shared.radius }

    static var animation: AnimationPresets { shared.animation }
}
