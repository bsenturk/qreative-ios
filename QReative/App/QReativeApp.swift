import SwiftUI
import GoogleMobileAds
import FirebaseCore
import RevenueCat
import AppTrackingTransparency

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct QReativeApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var tabCoordinator = MainTabCoordinator()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase

    init() {
        MobileAds.shared.start()
        Self.configureTabBarAppearance()

        // MARK: - RevenueCat
        // Public SDK key (safe to embed). Always the real App Store project —
        // no RevenueCat Test Store key, so every build (simulator, TestFlight,
        // App Store) reads real StoreKit/App Store Connect pricing via sandbox
        // or production purchases.
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif
        Purchases.configure(withAPIKey: "appl_xoGOJgGlZjFfqvmxrUxUECxPPms")
    }

    // MARK: - Tab Bar Appearance
    /// Gives the native tab bar a fixed, opaque background and fixed item colors
    /// so it no longer changes with the content scrolling behind it.
    private static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.backgroundPrimary)
        appearance.shadowColor = UIColor(Color.lineColor)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.selected.iconColor = UIColor(Color.accentPrimary)
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.accentPrimary)
        ]
        itemAppearance.normal.iconColor = UIColor(Color.ink3)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.ink3)
        ]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .environmentObject(appCoordinator)
                .environmentObject(tabCoordinator)
                .environment(\.tabCoordinator, tabCoordinator)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { requestTrackingIfNeeded() }
        }
        .onChange(of: appCoordinator.isOnboardingCompleted) { _, completed in
            if completed { requestTrackingIfNeeded() }
        }
    }

    /// Shows the App Tracking Transparency prompt once onboarding is done, so the
    /// user has app context before deciding. Required before AdMob may use the
    /// advertising identifier for personalized ads. Safe to call repeatedly — iOS
    /// only prompts while the status is `.notDetermined`, and the prompt only
    /// appears while the app is active (hence the scenePhase trigger too).
    private func requestTrackingIfNeeded() {
        guard appCoordinator.isOnboardingCompleted else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        // Small delay so the window is key/active on cold launch, otherwise the
        // system silently drops the prompt.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        #if DEBUG
        // Live language switching for testing localization (DEBUG only).
        // Re-keying on the selected language rebuilds the whole tree so every
        // localized string re-resolves immediately.
        DebugLanguageRoot()
        #else
        RootView()
        #endif
    }
}

#if DEBUG
/// Injects the runtime language and forces a full rebuild when it changes.
private struct DebugLanguageRoot: View {
    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        RootView()
            .environmentObject(languageManager)
            .environment(\.locale, languageManager.locale)
            .id(languageManager.current)
    }
}
#endif

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator

    var body: some View {
        Group {
            switch appCoordinator.currentRoute {
            case .onboarding:
                OnboardingView()
                    .transition(.opacity)

            case .mainTab:
                MainTabView()
                    .transition(.opacity)

            default:
                MainTabView()
            }
        }
        .animation(Theme.animation.easeInOut, value: appCoordinator.currentRoute)
        .fullScreenCover(isPresented: $appCoordinator.isPaywallPresented) {
            PaywallView()
        }
        .onAppear {
            appCoordinator.start()
            PurchasesManager.shared.start(coordinator: appCoordinator)
        }
    }
}

// MARK: - Preview
#Preview {
    RootView()
        .environmentObject(AppCoordinator())
        .environmentObject(MainTabCoordinator())
}
