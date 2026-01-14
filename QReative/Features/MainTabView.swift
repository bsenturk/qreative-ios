import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var tabCoordinator: MainTabCoordinator

    @Namespace private var tabAnimation

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .padding(.bottom, appCoordinator.isPremiumUser ? 84 : 134)

            VStack(spacing: 0) {
                if !appCoordinator.isPremiumUser {
                    BannerContainerView()
                }

                CustomTabBar(
                    selectedTab: Binding(
                        get: { tabCoordinator.selectedTab },
                        set: { selectTab($0) }
                    )
                )
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $appCoordinator.isPaywallPresented) {
            PaywallView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        ZStack {
            NavigationStack(path: tabCoordinator.navigationPath(for: .scan)) {
                ScanView()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
            }
            .opacity(tabCoordinator.selectedTab == .scan ? 1 : 0)
            .zIndex(tabCoordinator.selectedTab == .scan ? 1 : 0)

            NavigationStack(path: tabCoordinator.navigationPath(for: .create)) {
                CreateView()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
            }
            .opacity(tabCoordinator.selectedTab == .create ? 1 : 0)
            .zIndex(tabCoordinator.selectedTab == .create ? 1 : 0)

            NavigationStack(path: tabCoordinator.navigationPath(for: .history)) {
                HistoryView()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
            }
            .opacity(tabCoordinator.selectedTab == .history ? 1 : 0)
            .zIndex(tabCoordinator.selectedTab == .history ? 1 : 0)

            NavigationStack(path: tabCoordinator.navigationPath(for: .settings)) {
                SettingsView()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
            }
            .opacity(tabCoordinator.selectedTab == .settings ? 1 : 0)
            .zIndex(tabCoordinator.selectedTab == .settings ? 1 : 0)
        }
        .animation(Theme.animation.easeOut, value: tabCoordinator.selectedTab)
    }

    // MARK: - Tab Selection
    private func selectTab(_ tab: Tab) {
        guard tabCoordinator.selectedTab != tab else {
            tabCoordinator.popToRoot(tab: tab)
            return
        }

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(Theme.animation.spring) {
            tabCoordinator.selectedTab = tab
        }
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
            QRDetailPlaceholder(historyItemId: historyItemId)

        case .settings(let settingsRoute):
            SettingsDetailPlaceholder(route: settingsRoute)

        case .scanResult(let content):
            ScanResultPlaceholder(content: content)

        default:
            EmptyView()
        }
    }
}

// MARK: - Placeholder Views (for routes not yet implemented)
struct QRDetailPlaceholder: View {
    let historyItemId: String

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            Text("QR Detail: \(historyItemId)")
                .typography(.title1)
        }
    }
}

struct SettingsDetailPlaceholder: View {
    let route: SettingsRoute

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            Text(route.title)
                .typography(.title1)
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
