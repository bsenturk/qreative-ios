import SwiftUI
import StoreKit
import Combine

// MARK: - Settings Item
struct SettingsItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let showChevron: Bool
    let isRestore: Bool
    let action: () -> Void

    init(
        icon: String,
        iconColor: Color = .white,
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = true,
        isRestore: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.isRestore = isRestore
        self.action = action
    }
}

// MARK: - Settings Group
struct SettingsGroup: Identifiable {
    let id = UUID()
    let title: String
    let items: [SettingsItem]
}

// MARK: - Settings ViewModel
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var isPremium: Bool = false
    @Published var showPaywall: Bool = false
    @Published var showMembershipSheet: Bool = false
    @Published var showRestoreAlert: Bool = false
    @Published var restoreMessage: String = ""
    @Published var isRestoring: Bool = false
    @Published var showShareSheet: Bool = false
    @Published var showMailComposer: Bool = false

    // MARK: - Dependencies
    private weak var coordinator: AppCoordinator?
    private weak var tabCoordinator: MainTabCoordinator?

    // MARK: - App Info
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(version)"
    }

    // MARK: - Settings Groups
    var settingsGroups: [SettingsGroup] {
        [
            SettingsGroup(title: appLocalized("Support"), items: [
                SettingsItem(
                    icon: "questionmark.circle.fill",
                    iconColor: Color(hex: "34C759"),
                    title: appLocalized("Help & Support"),
                    action: { [weak self] in self?.openHelp() }
                ),
                SettingsItem(
                    icon: "arrow.clockwise",
                    iconColor: Color(hex: "FF9500"),
                    title: appLocalized("Restore Purchases"),
                    showChevron: false,
                    isRestore: true,
                    action: { [weak self] in
                        Task { await self?.restorePurchases() }
                    }
                ),
            ]),

            SettingsGroup(title: appLocalized("Feedback"), items: [
                SettingsItem(
                    icon: "star.fill",
                    iconColor: Color(hex: "FFCC00"),
                    title: appLocalized("Rate App"),
                    showChevron: false,
                    action: { [weak self] in self?.rateApp() }
                ),
                SettingsItem(
                    icon: "square.and.arrow.up.fill",
                    iconColor: Color(hex: "007AFF"),
                    title: appLocalized("Share App"),
                    showChevron: false,
                    action: { [weak self] in self?.shareApp() }
                ),
            ]),

            SettingsGroup(title: appLocalized("Legal"), items: [
                SettingsItem(
                    icon: "doc.text.fill",
                    iconColor: Color(hex: "8E8E93"),
                    title: appLocalized("Privacy Policy"),
                    action: { [weak self] in self?.openPrivacyPolicy() }
                ),
                SettingsItem(
                    icon: "doc.plaintext.fill",
                    iconColor: Color(hex: "8E8E93"),
                    title: appLocalized("Terms of Use"),
                    action: { [weak self] in self?.openTermsOfUse() }
                ),
            ]),
        ]
    }

    // MARK: - Init
    init() {}

    // MARK: - Coordinator Binding
    func bind(appCoordinator: AppCoordinator?, tabCoordinator: MainTabCoordinator?) {
        self.coordinator = appCoordinator
        self.tabCoordinator = tabCoordinator
        self.isPremium = appCoordinator?.isPremiumUser ?? false
    }

    // MARK: - Actions
    func showUpgrade() {
        HapticManager.shared.impact(.medium)

        coordinator?.showPaywall(source: "settings")
    }

    // MARK: - Membership
    func openMembership() {
        HapticManager.shared.impact(.light)

        showMembershipSheet = true
    }

    func goProFromMembership() {
        showMembershipSheet = false
        // Let the sheet dismiss before presenting the paywall.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.coordinator?.showPaywall(source: "membership")
        }
    }

    func manageSubscriptions() {
        HapticManager.shared.impact(.light)

        AnalyticsService.manageSubscriptionsTapped()

        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Navigation
    func openGeneral() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    func openHelp() {
        HapticManager.shared.impact(.light)

        showMailComposer = true
    }

    func openPrivacyPolicy() {
        HapticManager.shared.impact(.light)

        tabCoordinator?.pushToSettings(.settings(.privacy))
    }

    func openTermsOfUse() {
        HapticManager.shared.impact(.light)

        tabCoordinator?.pushToSettings(.settings(.termsOfUse))
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        guard !isRestoring else { return }

        isRestoring = true

        do {
            let restored = try await PurchasesManager.shared.restore()
            AnalyticsService.restorePurchases(success: restored)
            restoreMessage = restored
                ? appLocalized("Your purchases have been restored.")
                : appLocalized("No purchases to restore.")
        } catch {
            AnalyticsService.restorePurchases(success: false)
            restoreMessage = appLocalized("Failed to restore purchases. Please try again.")
        }

        isRestoring = false
        showRestoreAlert = true
    }

    // MARK: - Rate App
    func rateApp() {
        HapticManager.shared.impact(.light)

        AnalyticsService.rateAppTapped()

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    // MARK: - Share App
    func shareApp() {
        HapticManager.shared.impact(.light)

        AnalyticsService.shareAppTapped()

        showShareSheet = true
    }

    var shareItems: [Any] {
        let text = appLocalized("Check out QReative - Create beautiful QR codes!")
        let url = URL(string: "https://apps.apple.com/app/qreative/id123456789")!
        return [text, url]
    }
}
