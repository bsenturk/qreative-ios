import GoogleMobileAds
import UIKit
import Combine

// MARK: - App Open Ad Manager
@MainActor
final class AppOpenAdManager: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = AppOpenAdManager()

    // MARK: - Properties
    private var appOpenAd: AppOpenAd?
    private var isLoadingAd = false
    private var isShowingAd = false
    private var shouldShowWhenLoaded = false

    // MARK: - Init
    private override init() {
        super.init()
    }

    // MARK: - Load Ad
    func loadAd() {
        guard !isLoadingAd, appOpenAd == nil else { return }

        isLoadingAd = true

        let request = Request()
        AppOpenAd.load(
            with: AdUnitID.appOpen,
            request: request
        ) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoadingAd = false

                if let error = error {
                    print("App Open Ad failed to load: \(error.localizedDescription)")
                    self.shouldShowWhenLoaded = false
                    return
                }

                self.appOpenAd = ad
                self.appOpenAd?.fullScreenContentDelegate = self
                print("App Open Ad loaded successfully")

                if self.shouldShowWhenLoaded {
                    self.shouldShowWhenLoaded = false
                    self.showAdIfAvailable()
                }
            }
        }
    }

    // MARK: - Show Ad
    func showAdIfAvailable(isPremiumUser: Bool = false) {
        // Skip ads for premium users
        guard !isPremiumUser else {
            print("App Open Ad: Skipping for premium user")
            return
        }

        guard !isShowingAd else { return }

        guard let ad = appOpenAd else {
            shouldShowWhenLoaded = true
            loadAd()
            return
        }

        guard let rootViewController = UIApplication.shared.currentKeyWindow?.rootViewController else {
            print("App Open Ad: No root view controller")
            return
        }

        isShowingAd = true
        ad.present(from: rootViewController)
    }
}

// MARK: - FullScreenContentDelegate
extension AppOpenAdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            isShowingAd = false
            appOpenAd = nil
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("App Open Ad failed to present: \(error.localizedDescription)")
            isShowingAd = false
            appOpenAd = nil
        }
    }

    nonisolated func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("App Open Ad will present")
    }
}

// MARK: - UIApplication Extension
extension UIApplication {
    var currentKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
