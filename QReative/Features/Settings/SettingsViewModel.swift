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
    let action: () -> Void

    init(
        icon: String,
        iconColor: Color = .white,
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.action = action
    }
}

// MARK: - Settings Group
struct SettingsGroup: Identifiable {
    let id = UUID()
    let items: [SettingsItem]
}

// MARK: - Settings ViewModel
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var isPremium: Bool = false
    @Published var showPaywall: Bool = false
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
            SettingsGroup(items: [
                SettingsItem(
                    icon: "gearshape.fill",
                    iconColor: Color(hex: "8E8E93"),
                    title: "General",
                    action: { [weak self] in self?.openGeneral() }
                ),
            ]),

            SettingsGroup(items: [
                SettingsItem(
                    icon: "questionmark.circle.fill",
                    iconColor: Color(hex: "34C759"),
                    title: "Help & Support",
                    action: { [weak self] in self?.openHelp() }
                ),
                SettingsItem(
                    icon: "arrow.clockwise",
                    iconColor: Color(hex: "FF9500"),
                    title: "Restore Purchases",
                    showChevron: false,
                    action: { [weak self] in
                        Task { await self?.restorePurchases() }
                    }
                ),
            ]),

            SettingsGroup(items: [
                SettingsItem(
                    icon: "star.fill",
                    iconColor: Color(hex: "FFCC00"),
                    title: "Rate App",
                    showChevron: false,
                    action: { [weak self] in self?.rateApp() }
                ),
                SettingsItem(
                    icon: "square.and.arrow.up.fill",
                    iconColor: Color(hex: "007AFF"),
                    title: "Share App",
                    showChevron: false,
                    action: { [weak self] in self?.shareApp() }
                ),
            ]),

            SettingsGroup(items: [
                SettingsItem(
                    icon: "doc.text.fill",
                    iconColor: Color(hex: "8E8E93"),
                    title: "Privacy Policy",
                    action: { [weak self] in self?.openPrivacyPolicy() }
                ),
                SettingsItem(
                    icon: "doc.plaintext.fill",
                    iconColor: Color(hex: "8E8E93"),
                    title: "Terms of Use",
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
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        coordinator?.showPaywall()
    }

    // MARK: - Navigation
    func openGeneral() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    func openHelp() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        showMailComposer = true
    }

    func openPrivacyPolicy() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        tabCoordinator?.pushToSettings(.settings(.privacy))
    }

    func openTermsOfUse() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        tabCoordinator?.pushToSettings(.settings(.termsOfUse))
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        guard !isRestoring else { return }

        isRestoring = true

        do {
            try await Task.sleep(nanoseconds: 1_500_000_000)

            // TODO: Implement actual restore purchases logic with StoreKit
            // For now, always show "no purchases" message
            restoreMessage = "No purchases to restore."

        } catch {
            restoreMessage = "Failed to restore purchases. Please try again."
        }

        isRestoring = false
        showRestoreAlert = true
    }

    // MARK: - Rate App
    func rateApp() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    // MARK: - Share App
    func shareApp() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        showShareSheet = true
    }

    var shareItems: [Any] {
        let text = "Check out QReative - Create beautiful QR codes!"
        let url = URL(string: "https://apps.apple.com/app/qreative/id123456789")!
        return [text, url]
    }
}
