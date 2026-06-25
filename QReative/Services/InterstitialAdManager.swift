import GoogleMobileAds
import UIKit

// MARK: - Ad Unit IDs
enum AdUnitID {
    static var interstitial: String {
        #if DEBUG
        // Google's official test interstitial unit.
        return "ca-app-pub-3940256099942544/4411468910"
        #else
        return "ca-app-pub-2545255000258244/8334155046"
        #endif
    }
}

// MARK: - Interstitial Ad Manager
@MainActor
final class InterstitialAdManager: NSObject {

    // MARK: - Singleton
    static let shared = InterstitialAdManager()

    // MARK: - Properties
    private var interstitialAd: InterstitialAd?
    private var isLoadingAd = false
    private var isShowingAd = false
    private var onDismiss: (() -> Void)?

    // MARK: - Init
    private override init() {
        super.init()
    }

    // MARK: - Load
    func loadAd() {
        guard !isLoadingAd, interstitialAd == nil else { return }

        isLoadingAd = true

        let request = Request()
        InterstitialAd.load(with: AdUnitID.interstitial, request: request) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoadingAd = false

                if let error = error {
                    print("Interstitial failed to load: \(error.localizedDescription)")
                    return
                }

                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
            }
        }
    }

    // MARK: - Show
    /// Presents the interstitial for non-premium users, then calls `completion`
    /// once the ad is dismissed. If the user is premium or no ad is ready, it
    /// calls `completion` immediately and preloads an ad for next time.
    func showAd(isPremiumUser: Bool, completion: @escaping () -> Void) {
        guard !isPremiumUser else {
            completion()
            return
        }

        guard !isShowingAd else {
            completion()
            return
        }

        guard let ad = interstitialAd,
              let rootViewController = UIApplication.shared.currentKeyWindow?.rootViewController else {
            // No ad ready — don't block the user, just continue and preload.
            completion()
            loadAd()
            return
        }

        onDismiss = completion
        isShowingAd = true
        ad.present(from: rootViewController)
    }
}

// MARK: - FullScreenContentDelegate
extension InterstitialAdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            self.finishPresentation()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("Interstitial failed to present: \(error.localizedDescription)")
            self.finishPresentation()
        }
    }

    @MainActor
    private func finishPresentation() {
        isShowingAd = false
        interstitialAd = nil
        loadAd() // preload the next one
        let completion = onDismiss
        onDismiss = nil
        completion?()
    }
}

// MARK: - UIApplication Key Window
extension UIApplication {
    var currentKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
