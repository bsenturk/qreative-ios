import SwiftUI

// MARK: - Button Style Variant

enum ButtonVariant {
    case primary
    case secondary
    case outline
}

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let variant: ButtonVariant
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        variant: ButtonVariant = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button {
            guard !isLoading && !isDisabled else { return }
            triggerHaptic()
            action()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(borderOverlay)
            .shadow(color: shadowColor, radius: 16, x: 0, y: 8)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .opacity(isDisabled ? 0.5 : 1.0)
        .animation(Theme.animation.springQuick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(isDisabled || isLoading)
    }

    // MARK: - Styling

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .primary:
            LinearGradient.purpleGradient
        case .secondary:
            Color.white.opacity(0.05)
        case .outline:
            Color.clear
        }
    }

    private var textColor: Color {
        switch variant {
        case .primary:
            return .white
        case .secondary:
            return .textPrimary
        case .outline:
            return .accentPrimary
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch variant {
        case .primary:
            EmptyView()
        case .secondary:
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        case .outline:
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentPrimary, lineWidth: 2)
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .primary:
            return Color(hex: "6200EA").opacity(0.4)
        case .secondary, .outline:
            return .clear
        }
    }

    // MARK: - Haptic

    private func triggerHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - Convenience Initializers

extension PrimaryButton {
    /// Primary gradient button
    static func primary(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> PrimaryButton {
        PrimaryButton(title, icon: icon, variant: .primary, isLoading: isLoading, action: action)
    }

    /// Secondary glass button
    static func secondary(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> PrimaryButton {
        PrimaryButton(title, icon: icon, variant: .secondary, isLoading: isLoading, action: action)
    }

    /// Outline button
    static func outline(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> PrimaryButton {
        PrimaryButton(title, icon: icon, variant: .outline, action: action)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: 20) {
            // Primary
            PrimaryButton("Get Started", icon: "arrow.right") {
                print("Primary tapped")
            }

            // Primary loading
            PrimaryButton("Processing...", variant: .primary, isLoading: true) {}

            // Secondary
            PrimaryButton.secondary("Learn More", icon: "info.circle") {
                print("Secondary tapped")
            }

            // Outline
            PrimaryButton.outline("Skip", icon: "xmark") {
                print("Outline tapped")
            }

            // Disabled
            PrimaryButton("Disabled", isDisabled: true) {}
        }
        .padding(20)
    }
}
