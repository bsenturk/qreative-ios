import StoreKit
import UIKit

/// Requests an App Store review at meaningful usage milestones.
///
/// The system prompt is rate-limited by Apple (max ~3 per year), so we only ask
/// after the user has had repeated success scanning — at the 3rd, 10th, and 20th
/// scans.
enum ReviewManager {

    private static let scanCountKey = "qreative.totalScanCount"
    private static let reviewMilestones: Set<Int> = [3, 10, 20]

    /// Call once per successful scan (camera or photo). Increments the lifetime
    /// scan count and asks for a review when a milestone is reached.
    static func registerScanAndRequestReviewIfNeeded() {
        let defaults = UserDefaults.standard
        let newCount = defaults.integer(forKey: scanCountKey) + 1
        defaults.set(newCount, forKey: scanCountKey)

        guard reviewMilestones.contains(newCount) else { return }
        requestReview()
    }

    private static func requestReview() {
        // Small delay so the prompt appears after the scan-result UI has settled.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                return
            }
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
