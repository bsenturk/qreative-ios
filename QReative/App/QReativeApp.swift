import SwiftUI
import GoogleMobileAds

@main
struct QReativeApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var tabCoordinator = MainTabCoordinator()

    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appCoordinator)
                .environmentObject(tabCoordinator)
                .environment(\.appCoordinator, appCoordinator)
                .environment(\.tabCoordinator, tabCoordinator)
                .preferredColorScheme(.dark)
        }
    }
}

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
        }
    }
}

// MARK: - Preview
#Preview {
    RootView()
        .environmentObject(AppCoordinator())
        .environmentObject(MainTabCoordinator())
}
