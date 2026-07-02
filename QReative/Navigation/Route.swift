import SwiftUI

// MARK: - Tab
enum Tab: Int, Hashable, CaseIterable, Codable {
    case scan
    case create
    case history
    case settings

    var title: String {
        switch self {
        case .scan: return appLocalized("Scan")
        case .create: return appLocalized("Create")
        case .history: return appLocalized("History")
        case .settings: return appLocalized("Settings")
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

}

// MARK: - Settings Route
enum SettingsRoute: Hashable, Codable {
    case general
    case appIcon
    case helpSupport
    case restorePurchases
    case about
    case privacy
    case termsOfUse

    var title: String {
        switch self {
        case .general: return appLocalized("General")
        case .appIcon: return appLocalized("App Icon")
        case .helpSupport: return appLocalized("Help & Support")
        case .restorePurchases: return appLocalized("Restore Purchases")
        case .about: return appLocalized("About")
        case .privacy: return appLocalized("Privacy Policy")
        case .termsOfUse: return appLocalized("Terms of Use")
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
        case .termsOfUse: return "doc.plaintext"
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
}
