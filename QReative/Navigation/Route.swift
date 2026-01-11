import SwiftUI

// MARK: - Tab

enum Tab: Int, Hashable, CaseIterable, Codable {
    case scan
    case create
    case history
    case settings

    var title: String {
        switch self {
        case .scan: return "Scan"
        case .create: return "Create"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .scan: return "viewfinder"
        case .create: return "qrcode.viewfinder"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        }
    }

    var selectedIcon: String {
        switch self {
        case .scan: return "viewfinder"
        case .create: return "qrcode.viewfinder"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Settings Route

enum SettingsRoute: Hashable, Codable {
    case general
    case appIcon
    case helpSupport
    case restorePurchases
    case about
    case privacy

    var title: String {
        switch self {
        case .general: return "General"
        case .appIcon: return "App Icon"
        case .helpSupport: return "Help & Support"
        case .restorePurchases: return "Restore Purchases"
        case .about: return "About"
        case .privacy: return "Privacy Policy"
        }
    }

    var icon: String {
        switch self {
        case .general: return "slider.horizontal.3"
        case .appIcon: return "app.badge"
        case .helpSupport: return "questionmark.circle"
        case .restorePurchases: return "arrow.clockwise"
        case .about: return "info.circle"
        case .privacy: return "hand.raised"
        }
    }
}

// MARK: - Route

enum Route: Hashable {
    case onboarding
    case paywall
    case mainTab(Tab)
    case qrEditor(qrTypeId: String)
    case qrDetail(historyItemId: String)
    case settings(SettingsRoute)
    case scanResult(content: String)

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        switch self {
        case .onboarding:
            hasher.combine("onboarding")
        case .paywall:
            hasher.combine("paywall")
        case .mainTab(let tab):
            hasher.combine("mainTab")
            hasher.combine(tab)
        case .qrEditor(let qrTypeId):
            hasher.combine("qrEditor")
            hasher.combine(qrTypeId)
        case .qrDetail(let historyItemId):
            hasher.combine("qrDetail")
            hasher.combine(historyItemId)
        case .settings(let settingsRoute):
            hasher.combine("settings")
            hasher.combine(settingsRoute)
        case .scanResult(let content):
            hasher.combine("scanResult")
            hasher.combine(content)
        }
    }

    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs, rhs) {
        case (.onboarding, .onboarding):
            return true
        case (.paywall, .paywall):
            return true
        case (.mainTab(let a), .mainTab(let b)):
            return a == b
        case (.qrEditor(let a), .qrEditor(let b)):
            return a == b
        case (.qrDetail(let a), .qrDetail(let b)):
            return a == b
        case (.settings(let a), .settings(let b)):
            return a == b
        case (.scanResult(let a), .scanResult(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Router

@Observable
final class Router {
    var path = NavigationPath()
    var selectedTab: Tab = .scan
    var presentedSheet: Route?
    var presentedFullScreenCover: Route?

    // MARK: - Navigation

    func navigate(to route: Route) {
        path.append(route)
    }

    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func navigateToRoot() {
        path = NavigationPath()
    }

    func popTo(_ count: Int) {
        guard path.count >= count else { return }
        path.removeLast(count)
    }

    // MARK: - Tab

    func switchTab(to tab: Tab) {
        selectedTab = tab
    }

    // MARK: - Sheet

    func presentSheet(_ route: Route) {
        presentedSheet = route
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    // MARK: - Full Screen Cover

    func presentFullScreen(_ route: Route) {
        presentedFullScreenCover = route
    }

    func dismissFullScreen() {
        presentedFullScreenCover = nil
    }

    // MARK: - Reset

    func reset() {
        path = NavigationPath()
        selectedTab = .scan
        presentedSheet = nil
        presentedFullScreenCover = nil
    }
}

// MARK: - Environment Key

private struct RouterKey: EnvironmentKey {
    static let defaultValue = Router()
}

extension EnvironmentValues {
    var router: Router {
        get { self[RouterKey.self] }
        set { self[RouterKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    func withRouter(_ router: Router) -> some View {
        environment(\.router, router)
    }
}
