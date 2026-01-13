import SwiftUI
import Combine

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
    }

    // MARK: - Init
    init() {
        let onboardingCompleted = UserDefaults.standard.bool(forKey: Keys.onboardingCompleted)
        self.isOnboardingCompleted = onboardingCompleted
        self.isPremiumUser = UserDefaults.standard.bool(forKey: Keys.isPremiumUser)
        self.currentRoute = onboardingCompleted ? .mainTab(.scan) : .onboarding
    }

    // MARK: - Start
    func start() {
        if isOnboardingCompleted {
            currentRoute = .mainTab(.scan)
            AppOpenAdManager.shared.loadAd()
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
        isOnboardingCompleted = true
        AppOpenAdManager.shared.loadAd()
        navigate(to: .mainTab(.scan))
        showPaywall()
    }

    func skipOnboarding() {
        isOnboardingCompleted = true
        navigate(to: .mainTab(.scan))
    }

    func resetOnboarding() {
        isOnboardingCompleted = false
        navigate(to: .onboarding)
    }

    // MARK: - Paywall
    func showPaywall() {
        isPaywallPresented = true
    }

    func dismissPaywall() {
        isPaywallPresented = false
    }

    func handlePurchaseSuccess() {
        isPremiumUser = true
        UserDefaults.standard.set(true, forKey: Keys.isPremiumUser)
        dismissPaywall()
    }

    func restorePurchases() async -> Bool {
        return false
    }

    // MARK: - Premium Features
    func requirePremium(for feature: String, action: @escaping () -> Void) {
        if isPremiumUser {
            action()
        } else {
            showPaywall()
        }
    }

    // MARK: - Sheet Presentation
    func presentSheet(_ route: Route) {
        presentedSheet = route
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    // MARK: - Deep Link Handling
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else {
            return
        }

        switch host {
        case "scan":
            navigate(to: .mainTab(.scan))
        case "create":
            navigate(to: .mainTab(.create))
        case "premium":
            showPaywall()
        default:
            break
        }
    }
}

// MARK: - Environment Key
private struct AppCoordinatorKey: EnvironmentKey {
    static let defaultValue: AppCoordinator = AppCoordinator()
}

extension EnvironmentValues {
    var appCoordinator: AppCoordinator {
        get { self[AppCoordinatorKey.self] }
        set { self[AppCoordinatorKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    func withAppCoordinator(_ coordinator: AppCoordinator) -> some View {
        environment(\.appCoordinator, coordinator)
            .environmentObject(coordinator)
    }
}
