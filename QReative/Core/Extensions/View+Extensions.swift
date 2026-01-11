import SwiftUI

// MARK: - Haptic Style

enum HapticStyle {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case success
    case warning
    case error
    case selection
}

// MARK: - View Extensions

extension View {

    // MARK: - First Appear

    func onFirstAppear(_ action: @escaping () -> Void) -> some View {
        modifier(FirstAppearModifier(action: action))
    }

    // MARK: - Hide Keyboard

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func onTapHideKeyboard() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }

    // MARK: - Corner Radius

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }

    // MARK: - Shimmer Effect

    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }

    // MARK: - Glow Effect

    func glow(color: Color, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius / 3)
            .shadow(color: color.opacity(0.4), radius: radius / 2)
            .shadow(color: color.opacity(0.2), radius: radius)
    }

    func glowAnimated(color: Color, radius: CGFloat = 20, isActive: Bool = true) -> some View {
        modifier(GlowAnimatedModifier(color: color, radius: radius, isActive: isActive))
    }

    // MARK: - Haptic Feedback

    func hapticFeedback(_ style: HapticStyle) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                triggerHaptic(style)
            }
        )
    }

    func hapticFeedbackOnChange<Value: Equatable>(of value: Value, _ style: HapticStyle) -> some View {
        self.onChange(of: value) { _, _ in
            triggerHaptic(style)
        }
    }

    private func triggerHaptic(_ style: HapticStyle) {
        switch style {
        case .light:
            HapticManager.shared.lightTap()
        case .medium:
            HapticManager.shared.mediumTap()
        case .heavy:
            HapticManager.shared.heavyTap()
        case .soft:
            HapticManager.shared.softTap()
        case .rigid:
            HapticManager.shared.rigidTap()
        case .success:
            HapticManager.shared.success()
        case .warning:
            HapticManager.shared.warning()
        case .error:
            HapticManager.shared.error()
        case .selection:
            HapticManager.shared.selectionChanged()
        }
    }

    // MARK: - Conditional Modifier

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifLet<T, Content: View>(_ optional: T?, transform: (Self, T) -> Content) -> some View {
        if let value = optional {
            transform(self, value)
        } else {
            self
        }
    }

    // MARK: - Read Size

    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }

    // MARK: - Visible

    func visible(_ isVisible: Bool) -> some View {
        opacity(isVisible ? 1 : 0)
    }
}

// MARK: - First Appear Modifier

private struct FirstAppearModifier: ViewModifier {
    let action: () -> Void
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                action()
            }
    }
}

// MARK: - Rounded Corner Shape

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Shimmer Modifier

private struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + phase * geometry.size.width * 3)
                    }
                )
                .mask(content)
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - Glow Animated Modifier

private struct GlowAnimatedModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let isActive: Bool
    @State private var isGlowing = false

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isActive && isGlowing ? 0.6 : 0.3), radius: radius / 3)
            .shadow(color: color.opacity(isActive && isGlowing ? 0.4 : 0.2), radius: radius / 2)
            .shadow(color: color.opacity(isActive && isGlowing ? 0.2 : 0.1), radius: radius)
            .onAppear {
                guard isActive else { return }
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isGlowing = true
                }
            }
    }
}

// MARK: - Size Preference Key

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
