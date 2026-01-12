import GoogleMobileAds
import UIKit

// MARK: - App Open Ad Manager
@MainActor
final class AppOpenAdManager: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = AppOpenAdManager()

    // MARK: - Properties
    private var appOpenAd: GADAppOpenAd?
    private var isLoadingAd = false
    private var isShowingAd = false
    private var loadTime: Date?

    @Published private(set) var isAdReady = false

    private let shownKey = "qreative.appOpenAdShown"
    var shouldShowAfterCameraPermission = false

    // MARK: - Constants
    private let timeoutInterval: TimeInterval = 4 * 60 * 60

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
        guard !isLoadingAd, !isAdAvailable else { return }

        isLoadingAd = true

        let request = GADRequest()
        GADAppOpenAd.load(
            withAdUnitID: AdUnitID.appOpen,
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
                self?.loadTime = Date()
                self?.isAdReady = true
                print("App Open Ad loaded successfully")
            }
        }
    }

    // MARK: - Show Ad
    func showAdIfAvailable(completion: (() -> Void)? = nil) {
        guard !isShowingAd else {
            completion?()
            return
        }

        guard isAdAvailable else {
            loadAd()
            completion?()
            return
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion?()
            return
        }

        isShowingAd = true

        appOpenAd?.present(fromRootViewController: rootViewController)
    }

    func showAdOnceAfterPermission() {
        guard shouldShowAfterCameraPermission, !hasShownOnce else { return }

        showAdIfAvailable {
            self.hasShownOnce = true
            self.shouldShowAfterCameraPermission = false
        }

        hasShownOnce = true
        shouldShowAfterCameraPermission = false
    }

    // MARK: - Ad Availability
    private var isAdAvailable: Bool {
        guard let appOpenAd = appOpenAd, let loadTime = loadTime else {
            return false
        }

        let timeSinceLoad = Date().timeIntervalSince(loadTime)
        return timeSinceLoad < timeoutInterval
    }
}

// MARK: - GADFullScreenContentDelegate
extension AppOpenAdManager: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            isShowingAd = false
            isAdReady = false
            appOpenAd = nil
            loadTime = nil
            loadAd()
        }
    }

    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("App Open Ad failed to present: \(error.localizedDescription)")
            isShowingAd = false
            isAdReady = false
            appOpenAd = nil
            loadTime = nil
            loadAd()
        }
    }

    nonisolated func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("App Open Ad will present")
    }
}
