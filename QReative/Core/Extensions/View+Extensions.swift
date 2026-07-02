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

    // MARK: - Haptic Feedback
    func hapticFeedback(_ style: HapticStyle) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                triggerHaptic(style)
            }
        )
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
