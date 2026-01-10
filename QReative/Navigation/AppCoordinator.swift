import SwiftUI
import Combine

// MARK: - App Coordinator

@MainActor
final class AppCoordinator: ObservableObject {

    // MARK: - Published Properties

    @Published var currentRoute: Route = .onboarding
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
        self.isOnboardingCompleted = UserDefaults.standard.bool(forKey: Keys.onboardingCompleted)
        self.isPremiumUser = UserDefaults.standard.bool(forKey: Keys.isPremiumUser)
    }

    // MARK: - Start

    /// Determines initial route based on app state
    func start() {
        if isOnboardingCompleted {
            currentRoute = .mainTab(.scan)
        } else {
            currentRoute = .onboarding
        }
    }

    // MARK: - Navigation

    /// Navigate to a specific route
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

    /// Navigate back in the stack
    func navigateBack() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    /// Navigate to root of current tab
    func navigateToRoot() {
        navigationPath = NavigationPath()
    }

    // MARK: - Tab Navigation

    /// Switch to a specific tab
    func switchTab(to tab: Tab) {
        selectedTab = tab
        currentRoute = .mainTab(tab)
    }

    // MARK: - Onboarding

    /// Complete onboarding and navigate to main app
    func completeOnboarding() {
        isOnboardingCompleted = true
        showPaywall()
    }

    /// Skip onboarding (for debugging)
    func skipOnboarding() {
        isOnboardingCompleted = true
        navigate(to: .mainTab(.scan))
    }

    /// Reset onboarding (for debugging)
    func resetOnboarding() {
        isOnboardingCompleted = false
        navigate(to: .onboarding)
    }

    // MARK: - Paywall

    /// Show paywall screen
    func showPaywall() {
        isPaywallPresented = true
        currentRoute = .paywall
    }

    /// Dismiss paywall and continue to main app
    func dismissPaywall() {
        isPaywallPresented = false
        navigate(to: .mainTab(.scan))
    }

    /// Handle successful purchase
    func handlePurchaseSuccess() {
        isPremiumUser = true
        UserDefaults.standard.set(true, forKey: Keys.isPremiumUser)
        dismissPaywall()
    }

    /// Restore purchases
    func restorePurchases() async -> Bool {
        // TODO: Implement with StoreKit
        // For now, just return false
        return false
    }

    // MARK: - Premium Features

    /// Check if user can access premium feature, show paywall if not
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
        // TODO: Implement deep link handling
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
