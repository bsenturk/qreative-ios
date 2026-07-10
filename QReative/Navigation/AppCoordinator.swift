import SwiftUI
import Combine
import AVFoundation

// MARK: - App Coordinator
@MainActor
final class AppCoordinator: ObservableObject {

    // MARK: - Published Properties
    @Published var currentRoute: Route
    @Published var selectedTab: Tab = .scan
    @Published var navigationPath = NavigationPath()
    @Published var isPremiumUser: Bool = false
    @Published var isPaywallPresented: Bool = false
    @Published var presentedSheet: Route?

    // MARK: - UserDefaults Backed
    @Published var isOnboardingCompleted: Bool {
        didSet {
            UserDefaults.standard.set(isOnboardingCompleted, forKey: Keys.onboardingCompleted)
        }
    }

    // MARK: - Private
    private enum Keys {
        static let onboardingCompleted = "qreative.onboardingCompleted"
        static let isPremiumUser = "qreative.isPremiumUser"
        static let activationPaywallShown = "qreative.activationPaywallShown"
    }

    // MARK: - Init
    init() {
        if ProcessInfo.processInfo.arguments.contains("-UITestScreenshotMode") {
            self.isOnboardingCompleted = true
            self.isPremiumUser = true
            self.currentRoute = .mainTab(.scan)
            return
        }
        let onboardingCompleted = UserDefaults.standard.bool(forKey: Keys.onboardingCompleted)
        self.isOnboardingCompleted = onboardingCompleted
        self.isPremiumUser = UserDefaults.standard.bool(forKey: Keys.isPremiumUser)
        self.currentRoute = onboardingCompleted ? .mainTab(.scan) : .onboarding
    }

    // MARK: - Start
    func start() {
        AnalyticsService.setMembership(isPremium: isPremiumUser)
        if isOnboardingCompleted {
            currentRoute = .mainTab(.scan)
        } else {
            currentRoute = .onboarding
        }
    }

    // MARK: - Navigation
    func navigate(to route: Route) {
        switch route {
        case .mainTab(let tab):
            currentRoute = route
            selectedTab = tab
            navigationPath = NavigationPath()

        case .onboarding, .paywall:
            currentRoute = route

        case .qrEditor, .qrDetail, .settings, .scanResult:
            navigationPath.append(route)

        }
    }

    func navigateBack() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    func navigateToRoot() {
        navigationPath = NavigationPath()
    }

    // MARK: - Tab Navigation
    func switchTab(to tab: Tab) {
        selectedTab = tab
        currentRoute = .mainTab(tab)
    }

    // MARK: - Onboarding
    func completeOnboarding() {
        AnalyticsService.onboardingCompleted()
        finishOnboarding()
    }

    func skipOnboarding(atStep step: Int = 0) {
        AnalyticsService.onboardingSkipped(step: step)
        finishOnboarding()
    }

    private func finishOnboarding() {
        isOnboardingCompleted = true
        navigate(to: .mainTab(.scan))
        // Prime the camera permission in context (the onboarding explained scanning),
        // instead of a cold prompt later. The paywall is deferred until the user has
        // experienced first value (their first scan) — see maybeShowActivationPaywall().
        primeCameraPermission()
    }

    private func primeCameraPermission() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined else { return }
        AVCaptureDevice.requestAccess(for: .video) { _ in }
    }

    // MARK: - Activation Paywall (deferred, shown once after first value moment)
    func maybeShowActivationPaywall() {
        guard !isPremiumUser else { return }
        guard !UserDefaults.standard.bool(forKey: Keys.activationPaywallShown) else { return }

        UserDefaults.standard.set(true, forKey: Keys.activationPaywallShown)
        // Let the current sheet/transition settle before presenting the paywall.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showPaywall(source: "activation")
        }
    }

    func resetOnboarding() {
        isOnboardingCompleted = false
        navigate(to: .onboarding)
    }

    // MARK: - Paywall
    func showPaywall(source: String = "app") {
        AnalyticsService.paywallShown(source: source)
        isPaywallPresented = true
    }

    func dismissPaywall() {
        isPaywallPresented = false
    }

    func handlePurchaseSuccess() {
        isPremiumUser = true
        UserDefaults.standard.set(true, forKey: Keys.isPremiumUser)
        AnalyticsService.setMembership(isPremium: true)
        dismissPaywall()
    }

    /// Single sync point for RevenueCat entitlement changes. Keeps the app-wide
    /// `isPremiumUser` gating flag aligned with the user's real subscription.
    func updatePremium(_ isPro: Bool) {
        // Screenshot mode force-unlocks premium; don't let the (unpurchased) real
        // entitlement status overwrite that once RevenueCat responds.
        guard !ProcessInfo.processInfo.arguments.contains("-UITestScreenshotMode") else { return }
        guard isPremiumUser != isPro else { return }
        isPremiumUser = isPro
        UserDefaults.standard.set(isPro, forKey: Keys.isPremiumUser)
        AnalyticsService.setMembership(isPremium: isPro)
    }

    // MARK: - Sheet Presentation
    func presentSheet(_ route: Route) {
        presentedSheet = route
    }

    func dismissSheet() {
        presentedSheet = nil
    }
}
