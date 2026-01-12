import UIKit

// MARK: - Haptic Manager
final class HapticManager {

    // MARK: - Singleton
    static let shared = HapticManager()

    // MARK: - Generators
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    // MARK: - Init
    private init() {
        prepareGenerators()
    }

    // MARK: - Prepare
    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        notification.prepare()
        selection.prepare()
    }

    // MARK: - Impact Feedback
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft:
            impactSoft.impactOccurred()
        case .rigid:
            impactRigid.impactOccurred()
        @unknown default:
            impactMedium.impactOccurred()
        }
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) {
        switch style {
        case .light:
            impactLight.impactOccurred(intensity: intensity)
        case .medium:
            impactMedium.impactOccurred(intensity: intensity)
        case .heavy:
            impactHeavy.impactOccurred(intensity: intensity)
        case .soft:
            impactSoft.impactOccurred(intensity: intensity)
        case .rigid:
            impactRigid.impactOccurred(intensity: intensity)
        @unknown default:
            impactMedium.impactOccurred(intensity: intensity)
        }
    }

    // MARK: - Notification Feedback
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.notificationOccurred(type)
    }

    // MARK: - Selection Feedback
    func selectionChanged() {
        selection.selectionChanged()
    }

    // MARK: - Convenience Methods
    func lightTap() {
        impactLight.impactOccurred()
    }

    func mediumTap() {
        impactMedium.impactOccurred()
    }

    func heavyTap() {
        impactHeavy.impactOccurred()
    }

    func softTap() {
        impactSoft.impactOccurred()
    }

    func rigidTap() {
        impactRigid.impactOccurred()
    }

    func success() {
        notification.notificationOccurred(.success)
    }

    func warning() {
        notification.notificationOccurred(.warning)
    }

    func error() {
        notification.notificationOccurred(.error)
    }
}

// MARK: - SwiftUI Extension
import SwiftUI

extension View {
    func hapticOnTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticManager.shared.impact(style)
            }
        )
    }

    func hapticOnChange<Value: Equatable>(of value: Value, _ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onChange(of: value) { _, _ in
            HapticManager.shared.impact(style)
        }
    }
}
