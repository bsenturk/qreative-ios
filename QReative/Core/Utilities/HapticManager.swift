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

    // MARK: - Enabled State
    /// Reads the user's "Haptic feedback" preference directly from UserDefaults
    /// (key owned by `AppSettings`) so haptics can be gated from any context.
    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "settings.hapticFeedback") as? Bool ?? true
    }

    // MARK: - Impact Feedback
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
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

    // MARK: - Notification Feedback
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notification.notificationOccurred(type)
    }

    // MARK: - Selection Feedback
    func selectionChanged() {
        guard isEnabled else { return }
        selection.selectionChanged()
    }

    // MARK: - Convenience Methods
    // All route through the gated core methods above so the "Haptic feedback"
    // setting controls every haptic in one place.
    func lightTap() { impact(.light) }
    func mediumTap() { impact(.medium) }
    func heavyTap() { impact(.heavy) }
    func softTap() { impact(.soft) }
    func rigidTap() { impact(.rigid) }
    func success() { notification(.success) }
    func warning() { notification(.warning) }
    func error() { notification(.error) }
}

