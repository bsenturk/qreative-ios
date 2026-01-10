import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var tabCoordinator: MainTabCoordinator

    @Namespace private var tabAnimation

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            tabContent
                .padding(.bottom, 84)

            // Custom Tab Bar
            CustomTabBar(
                selectedTab: Binding(
                    get: { tabCoordinator.selectedTab },
                    set: { selectTab($0) }
                )
            )
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
            // Scan Tab
            NavigationStack(path: tabCoordinator.navigationPath(for: .scan)) {
                ScanViewPlaceholder()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
            }
            .opacity(tabCoordinator.selectedTab == .scan ? 1 : 0)
            .zIndex(tabCoordinator.selectedTab == .scan ? 1 : 0)

            // Create Tab
            NavigationStack(path: tabCoordinator.navigationPath(for: .create)) {
                CreateViewPlaceholder()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
            }
            .opacity(tabCoordinator.selectedTab == .create ? 1 : 0)
            .zIndex(tabCoordinator.selectedTab == .create ? 1 : 0)

            // History Tab
            NavigationStack(path: tabCoordinator.navigationPath(for: .history)) {
                HistoryViewPlaceholder()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route)
                    }
            }
            .opacity(tabCoordinator.selectedTab == .history ? 1 : 0)
            .zIndex(tabCoordinator.selectedTab == .history ? 1 : 0)

            // Settings Tab
            NavigationStack(path: tabCoordinator.navigationPath(for: .settings)) {
                SettingsViewPlaceholder()
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
            // Double tap - pop to root
            tabCoordinator.popToRoot(tab: tab)
            return
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Animate tab change
        withAnimation(Theme.animation.spring) {
            tabCoordinator.selectedTab = tab
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .qrEditor(let qrTypeId):
            QREditorPlaceholder(qrTypeId: qrTypeId)

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

// MARK: - Placeholder Views

struct ScanViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentPrimary)
                Text("Scan")
                    .typography(.title1)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct CreateViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentPrimary)
                Text("Create")
                    .typography(.title1)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct HistoryViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentPrimary)
                Text("History")
                    .typography(.title1)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct SettingsViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentPrimary)
                Text("Settings")
                    .typography(.title1)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct QREditorPlaceholder: View {
    let qrTypeId: String

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            Text("QR Editor: \(qrTypeId)")
                .typography(.title1)
        }
    }
}

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
