import SwiftUI
import Combine

// MARK: - Main Tab Coordinator
@MainActor
final class MainTabCoordinator: ObservableObject {

    // MARK: - Published Properties
    @Published var selectedTab: Tab = .scan

    @Published var scanNavigationPath = NavigationPath()
    @Published var createNavigationPath = NavigationPath()
    @Published var historyNavigationPath = NavigationPath()
    @Published var settingsNavigationPath = NavigationPath()

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        setupTabChangeObserver()
    }

    // MARK: - Tab Selection
    func selectTab(_ tab: Tab) {
        guard selectedTab != tab else {
            popToRoot(tab: tab)
            return
        }

        triggerHaptic(.light)
        selectedTab = tab
    }

    // MARK: - Navigation Path Access
    func navigationPath(for tab: Tab) -> Binding<NavigationPath> {
        switch tab {
        case .scan:
            return Binding(
                get: { self.scanNavigationPath },
                set: { self.scanNavigationPath = $0 }
            )
        case .create:
            return Binding(
                get: { self.createNavigationPath },
                set: { self.createNavigationPath = $0 }
            )
        case .history:
            return Binding(
                get: { self.historyNavigationPath },
                set: { self.historyNavigationPath = $0 }
            )
        case .settings:
            return Binding(
                get: { self.settingsNavigationPath },
                set: { self.settingsNavigationPath = $0 }
            )
        }
    }

    var currentNavigationPath: Binding<NavigationPath> {
        navigationPath(for: selectedTab)
    }

    // MARK: - Push Navigation
    func pushToScan(_ route: Route) {
        scanNavigationPath.append(route)
        if selectedTab != .scan {
            selectedTab = .scan
        }
    }

    func pushToCreate(_ route: Route) {
        createNavigationPath.append(route)
        if selectedTab != .create {
            selectedTab = .create
        }
    }

    func pushToHistory(_ route: Route) {
        historyNavigationPath.append(route)
        if selectedTab != .history {
            selectedTab = .history
        }
    }

    func pushToSettings(_ route: Route) {
        settingsNavigationPath.append(route)
        if selectedTab != .settings {
            selectedTab = .settings
        }
    }

    func push(_ route: Route) {
        switch selectedTab {
        case .scan:
            scanNavigationPath.append(route)
        case .create:
            createNavigationPath.append(route)
        case .history:
            historyNavigationPath.append(route)
        case .settings:
            settingsNavigationPath.append(route)
        }
    }

    // MARK: - Pop Navigation
    func pop() {
        switch selectedTab {
        case .scan:
            if !scanNavigationPath.isEmpty { scanNavigationPath.removeLast() }
        case .create:
            if !createNavigationPath.isEmpty { createNavigationPath.removeLast() }
        case .history:
            if !historyNavigationPath.isEmpty { historyNavigationPath.removeLast() }
        case .settings:
            if !settingsNavigationPath.isEmpty { settingsNavigationPath.removeLast() }
        }
    }

    func popToRoot(tab: Tab) {
        switch tab {
        case .scan:
            scanNavigationPath = NavigationPath()
        case .create:
            createNavigationPath = NavigationPath()
        case .history:
            historyNavigationPath = NavigationPath()
        case .settings:
            settingsNavigationPath = NavigationPath()
        }
    }

    func popToRoot() {
        popToRoot(tab: selectedTab)
    }

    func resetAllPaths() {
        scanNavigationPath = NavigationPath()
        createNavigationPath = NavigationPath()
        historyNavigationPath = NavigationPath()
        settingsNavigationPath = NavigationPath()
    }

    // MARK: - Stack Info
    var canPopCurrentTab: Bool {
        switch selectedTab {
        case .scan: return !scanNavigationPath.isEmpty
        case .create: return !createNavigationPath.isEmpty
        case .history: return !historyNavigationPath.isEmpty
        case .settings: return !settingsNavigationPath.isEmpty
        }
    }

    func stackDepth(for tab: Tab) -> Int {
        switch tab {
        case .scan: return scanNavigationPath.count
        case .create: return createNavigationPath.count
        case .history: return historyNavigationPath.count
        case .settings: return settingsNavigationPath.count
        }
    }

    // MARK: - Private Methods
    private func setupTabChangeObserver() {
        $selectedTab
            .dropFirst()
            .sink { [weak self] _ in
                self?.triggerHaptic(.light)
            }
            .store(in: &cancellables)
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        HapticManager.shared.impact(style)
    }
}

// MARK: - Environment Key
private struct MainTabCoordinatorKey: EnvironmentKey {
    static let defaultValue = MainTabCoordinator()
}

extension EnvironmentValues {
    var tabCoordinator: MainTabCoordinator {
        get { self[MainTabCoordinatorKey.self] }
        set { self[MainTabCoordinatorKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    func withTabCoordinator(_ coordinator: MainTabCoordinator) -> some View {
        environment(\.tabCoordinator, coordinator)
            .environmentObject(coordinator)
    }
}
