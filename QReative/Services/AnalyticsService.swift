import Foundation
import FirebaseAnalytics

/// Centralized Firebase Analytics wrapper.
///
/// Keeps event names and parameters consistent and gives a single place to
/// add, change, or disable tracking. Event names use the `object_action`
/// convention (lowercase + underscores); contextual data goes in parameters.
enum AnalyticsService {

    // MARK: - Screens
    static func logScreen(_ name: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: name
        ])
    }

    // MARK: - Scan
    /// A QR code / barcode was successfully read. `source` is "camera" or "photo".
    static func qrScanned(resultType: String, source: String) {
        Analytics.logEvent("qr_scanned", parameters: [
            "result_type": resultType,
            "source": source
        ])
    }

    static func scanFailed(source: String, reason: String) {
        Analytics.logEvent("scan_failed", parameters: [
            "source": source,
            "reason": reason
        ])
    }

    // MARK: - Create
    static func qrTypeSelected(_ type: String) {
        Analytics.logEvent("qr_type_selected", parameters: ["qr_type": type])
    }

    static func qrCreated(
        type: String,
        color: String,
        shape: String,
        hasLogo: Bool,
        hasEmoji: Bool,
        isPremium: Bool
    ) {
        Analytics.logEvent("qr_created", parameters: [
            "qr_type": type,
            "color": color,
            "shape": shape,
            "has_logo": hasLogo,
            "has_emoji": hasEmoji,
            "is_premium": isPremium
        ])
    }

    /// A locked PRO feature was tapped by a free user (e.g. "color", "shape",
    /// "logo", "emoji", "qr_type_<id>"). Reveals which features drive upgrades.
    static func premiumGateHit(feature: String) {
        Analytics.logEvent("premium_gate_hit", parameters: ["feature": feature])
    }

    // MARK: - Paywall / Purchase
    static func paywallShown(source: String) {
        Analytics.logEvent("paywall_shown", parameters: ["source": source])
    }

    static func purchaseCompleted(plan: String) {
        Analytics.logEvent("purchase_completed", parameters: ["plan": plan])
    }

    static func restorePurchases(success: Bool) {
        Analytics.logEvent("restore_purchases", parameters: ["success": success])
    }

    // MARK: - Onboarding
    /// A specific onboarding slide became visible. Drives per-step funnel
    /// drop-off analysis (which slide loses people).
    static func onboardingStepViewed(step: Int, name: String) {
        Analytics.logEvent("onboarding_step_viewed", parameters: [
            "step_number": step,
            "step_name": name
        ])
    }

    static func onboardingCompleted() {
        Analytics.logEvent("onboarding_completed", parameters: nil)
    }

    static func onboardingSkipped(step: Int) {
        Analytics.logEvent("onboarding_skipped", parameters: ["step_number": step])
    }

    // MARK: - History
    static func historyItemShared() {
        Analytics.logEvent("history_item_shared", parameters: nil)
    }

    static func historyItemDeleted() {
        Analytics.logEvent("history_item_deleted", parameters: nil)
    }

    // MARK: - Settings
    static func rateAppTapped() {
        Analytics.logEvent("rate_app_tapped", parameters: nil)
    }

    static func shareAppTapped() {
        Analytics.logEvent("share_app_tapped", parameters: nil)
    }

    static func manageSubscriptionsTapped() {
        Analytics.logEvent("manage_subscriptions_tapped", parameters: nil)
    }

    // MARK: - User Properties
    static func setMembership(isPremium: Bool) {
        Analytics.setUserProperty(isPremium ? "pro" : "free", forName: "membership")
    }
}
