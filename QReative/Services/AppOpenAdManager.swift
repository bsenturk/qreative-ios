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

    private let shownKey = "qreative.appOpenAdShown"
    var shouldShowAfterCameraPermission = false

    // MARK: - Init
    private override init() {
        super.init()
    }

    // MARK: - First Time Check
    var hasShownOnce: Bool {
        get { UserDefaults.standard.bool(forKey: shownKey) }
        set { UserDefaults.standard.set(newValue, forKey: shownKey) }
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
            Task { @MainActor in
                self?.isLoadingAd = false

                if let error = error {
                    print("App Open Ad failed to load: \(error.localizedDescription)")
                    return
                }

                self?.appOpenAd = ad
                self?.appOpenAd?.fullScreenContentDelegate = self
                print("App Open Ad loaded successfully")
            }
        }
    }

    // MARK: - Show Ad
    func showAdIfAvailable() {
        guard !isShowingAd, let ad = appOpenAd else {
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

    func showAdOnceAfterPermission() {
        guard shouldShowAfterCameraPermission, !hasShownOnce else { return }

        hasShownOnce = true
        shouldShowAfterCameraPermission = false
        showAdIfAvailable()
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
