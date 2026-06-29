import SwiftUI

// MARK: - Button Style Variant
enum ButtonVariant {
    case primary    // ink dark background
    case accent     // cobalt accent background
    case soft       // surface-2 background
    case ghost      // transparent
    case secondary  // kept for compatibility
    case outline    // kept for compatibility
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
            HStack(spacing: 9) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.9)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.2)
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .padding(.horizontal, 22)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(borderOverlay)
            .shadow(color: shadowColor, radius: 16, x: 0, y: 8)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(isDisabled ? 0.4 : 1.0)
        .animation(.spring(response: 0.14, dampingFraction: 0.7), value: isPressed)
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
        case .primary, .secondary:
            Color.ink
        case .accent:
            Color.accentPrimary
        case .soft, .outline:
            Color.surface2
        case .ghost:
            Color.clear
        }
    }

    private var textColor: Color {
        switch variant {
        case .primary, .secondary, .accent:
            return Color.backgroundPrimary
        case .soft, .outline, .ghost:
            return .textPrimary
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch variant {
        case .soft, .outline:
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.lineColor, lineWidth: 1)
        default:
            EmptyView()
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .primary, .secondary:
            return Color.ink.opacity(0.18)
        case .accent:
            return Color.accentPrimary.opacity(0.30)
        case .soft, .outline, .ghost:
            return .clear
        }
    }

    // MARK: - Haptic
    private func triggerHaptic() {
        HapticManager.shared.impact(.medium)
    }
}

// MARK: - Convenience Initializers
extension PrimaryButton {
    static func primary(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> PrimaryButton {
        PrimaryButton(title, icon: icon, variant: .primary, isLoading: isLoading, action: action)
    }

    static func secondary(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> PrimaryButton {
        PrimaryButton(title, icon: icon, variant: .soft, isLoading: isLoading, action: action)
    }

    static func outline(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> PrimaryButton {
        PrimaryButton(title, icon: icon, variant: .soft, action: action)
    }
}
