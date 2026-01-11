import SwiftUI

// MARK: - Animation Extensions

extension Animation {

    // MARK: - Spring Animations

    static let gentleSpring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let bouncySpring = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let snappySpring = Animation.spring(response: 0.25, dampingFraction: 0.8)

    // MARK: - Timing Animations

    static let smoothEaseOut = Animation.easeOut(duration: 0.3)
    static let mediumEaseOut = Animation.easeOut(duration: 0.4)
    static let slowEaseOut = Animation.easeOut(duration: 0.6)

    static let smoothEaseIn = Animation.easeIn(duration: 0.3)
    static let smoothEaseInOut = Animation.easeInOut(duration: 0.35)

    // MARK: - Stagger Delay

    static func staggered(index: Int, baseDelay: Double = 0.05) -> Animation {
        .spring(response: 0.4, dampingFraction: 0.75)
        .delay(Double(index) * baseDelay)
    }

    static func staggeredEaseOut(index: Int, baseDelay: Double = 0.08) -> Animation {
        .easeOut(duration: 0.4)
        .delay(Double(index) * baseDelay)
    }

    // MARK: - Loop Animations

    static let floatLoop = Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)
    static let pulseLoop = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    static let scanLineLoop = Animation.linear(duration: 2).repeatForever(autoreverses: false)
    static let glowLoop = Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)

    // MARK: - Transition Helpers

    static func delayedSpring(_ delay: Double) -> Animation {
        .spring(response: 0.4, dampingFraction: 0.75).delay(delay)
    }
}

// MARK: - Transition Extensions

extension AnyTransition {

    // MARK: - Slide Transitions

    static let slideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity)
    static let slideDown = AnyTransition.move(edge: .top).combined(with: .opacity)
    static let slideLeft = AnyTransition.move(edge: .trailing).combined(with: .opacity)
    static let slideRight = AnyTransition.move(edge: .leading).combined(with: .opacity)

    // MARK: - Scale Transitions

    static let scaleUp = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
    static let scaleDown = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
    static let popIn = AnyTransition.scale(scale: 0.5).combined(with: .opacity)

    // MARK: - Custom Transitions

    static let fadeSlideUp = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .opacity
    )

    static let cardPresent = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .bottom).combined(with: .opacity)
    )

    static func staggeredSlide(index: Int) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing)
                .combined(with: .opacity)
                .animation(.staggered(index: index)),
            removal: .opacity
        )
    }
}

// MARK: - Animation Modifiers

struct FloatingAnimation: ViewModifier {
    @State private var isFloating = false
    let duration: Double
    let distance: CGFloat

    init(duration: Double = 3, distance: CGFloat = 10) {
        self.duration = duration
        self.distance = distance
    }

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -distance : distance)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isFloating = true
                }
            }
    }
}

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double

    init(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.5) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

struct FadeInAnimation: ViewModifier {
    @State private var isVisible = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct SlideInAnimation: ViewModifier {
    @State private var isVisible = false
    let edge: Edge
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(
                x: isVisible ? 0 : (edge == .leading ? -50 : (edge == .trailing ? 50 : 0)),
                y: isVisible ? 0 : (edge == .top ? -50 : (edge == .bottom ? 50 : 0))
            )
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct PressableStyle: ButtonStyle {
    let scale: CGFloat

    init(scale: CGFloat = 0.95) {
        self.scale = scale
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func floating(duration: Double = 3, distance: CGFloat = 10) -> some View {
        modifier(FloatingAnimation(duration: duration, distance: distance))
    }

    func pulsing(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.5) -> some View {
        modifier(PulseAnimation(minScale: minScale, maxScale: maxScale, duration: duration))
    }

    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeInAnimation(delay: delay))
    }

    func slideIn(from edge: Edge = .bottom, delay: Double = 0) -> some View {
        modifier(SlideInAnimation(edge: edge, delay: delay))
    }

    func staggeredAppear(index: Int, baseDelay: Double = 0.08) -> some View {
        fadeIn(delay: Double(index) * baseDelay)
    }

    func pressable(scale: CGFloat = 0.95) -> some View {
        self.buttonStyle(PressableStyle(scale: scale))
    }
}
