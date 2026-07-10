import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var tabCoordinator: MainTabCoordinator

    var body: some View {
        TabView(selection: tabSelection) {
            NavigationStack(path: tabCoordinator.navigationPath(for: .scan)) {
                ScanView()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
                    .fixedTabBarBackground()
            }
            .tabItem { Label(Tab.scan.title, systemImage: Tab.scan.icon) }
            .tag(Tab.scan)

            NavigationStack(path: tabCoordinator.navigationPath(for: .create)) {
                CreateView()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
                    .fixedTabBarBackground()
            }
            .tabItem { Label(Tab.create.title, systemImage: Tab.create.icon) }
            .tag(Tab.create)

            NavigationStack(path: tabCoordinator.navigationPath(for: .history)) {
                HistoryView()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
                    .fixedTabBarBackground()
            }
            .tabItem { Label(Tab.history.title, systemImage: Tab.history.icon) }
            .tag(Tab.history)

            NavigationStack(path: tabCoordinator.navigationPath(for: .settings)) {
                SettingsView()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
                    .fixedTabBarBackground()
            }
            .tabItem { Label(Tab.settings.title, systemImage: Tab.settings.icon) }
            .tag(Tab.settings)
        }
        .tint(Color.accentPrimary)
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Tab Selection
    private var tabSelection: Binding<Tab> {
        Binding(
            get: { tabCoordinator.selectedTab },
            set: { selectTab($0) }
        )
    }

    private func selectTab(_ tab: Tab) {
        // Re-tapping the active tab pops its stack to root.
        guard tabCoordinator.selectedTab != tab else {
            tabCoordinator.popToRoot(tab: tab)
            return
        }
        tabCoordinator.selectedTab = tab
    }

    // MARK: - Navigation Destinations
    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .qrEditor(let qrTypeId):
            if let qrType = QRType.fromId(qrTypeId) {
                QREditorView(viewModel: QREditorViewModel(qrType: qrType))
            } else {
                EmptyView()
            }

        case .qrDetail(let historyItemId):
            QRDetailView(historyItemId: historyItemId)

        case .settings(let settingsRoute):
            SettingsDetailPlaceholder(route: settingsRoute)

        case .scanResult(let content):
            ScanResultPlaceholder(content: content)

        default:
            EmptyView()
        }
    }
}

// MARK: - Fixed Tab Bar Background
private extension View {
    /// Forces the tab bar to keep one fixed, always-visible background color so it
    /// doesn't switch between opaque/translucent appearances as tabs change.
    func fixedTabBarBackground() -> some View {
        self
            .toolbarBackground(Color.backgroundPrimary, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}

// MARK: - Placeholder Views (for routes not yet implemented)
struct SettingsDetailPlaceholder: View {
    let route: SettingsRoute

    var body: some View {
        switch route {
        case .privacy:
            PrivacyPolicyView()
        case .termsOfUse:
            TermsOfUseView()
        default:
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                Text(route.title)
                    .typography(.title1)
            }
        }
    }
}

struct ScanResultPlaceholder: View {
    let content: String

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Scan Result")
                    .typography(.title1)
                Text(content)
                    .typography(.body, color: .textSecondary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AppCoordinator())
        .environmentObject(MainTabCoordinator())
}
