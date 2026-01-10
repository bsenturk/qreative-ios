import SwiftUI
import Combine

// MARK: - Create ViewModel

@MainActor
final class CreateViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var showMoreTypes: Bool = false
    @Published var selectedType: QRTypeTemplate?
    @Published var navigateToEditor: Bool = false

    // MARK: - Properties

    /// Primary QR types shown in the main grid
    let primaryTemplates: [QRTypeTemplate] = [
        QRTypeTemplate(id: "website", type: .website(url: ""), isPremium: false),
        QRTypeTemplate(id: "wifi", type: .wifi(ssid: "", password: "", security: .wpa), isPremium: false),
        QRTypeTemplate(id: "instagram", type: .instagram(username: ""), isPremium: false),
        QRTypeTemplate(id: "text", type: .text(content: ""), isPremium: false),
        QRTypeTemplate(id: "vcard", type: .vcard(name: "", phone: nil, email: nil, company: nil), isPremium: true),
    ]

    /// Additional QR types shown in "More" sheet
    let additionalTemplates: [QRTypeTemplate] = [
        QRTypeTemplate(id: "email", type: .email(address: "", subject: nil, body: nil), isPremium: false),
        QRTypeTemplate(id: "phone", type: .phone(number: ""), isPremium: false),
        QRTypeTemplate(id: "sms", type: .sms(number: "", message: nil), isPremium: true),
    ]

    /// All templates combined
    var allTemplates: [QRTypeTemplate] {
        primaryTemplates + additionalTemplates
    }

    // MARK: - Dependencies

    private weak var coordinator: AppCoordinator?
    private weak var tabCoordinator: MainTabCoordinator?

    // MARK: - Init

    init() {}

    // MARK: - Coordinator Binding

    func bind(appCoordinator: AppCoordinator?, tabCoordinator: MainTabCoordinator?) {
        self.coordinator = appCoordinator
        self.tabCoordinator = tabCoordinator
    }

    // MARK: - Actions

    /// Select a QR type and navigate to editor
    func selectType(_ template: QRTypeTemplate) {
        // Check premium
        if template.isPremium && !(coordinator?.isPremiumUser ?? false) {
            coordinator?.showPaywall()
            return
        }

        selectedType = template

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Navigate to editor
        tabCoordinator?.pushToCreate(.qrEditor(qrTypeId: template.id))
    }

    /// Show more QR type options
    func showMoreOptions() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        showMoreTypes = true
    }

    /// Dismiss more options sheet
    func dismissMoreOptions() {
        showMoreTypes = false
    }

    /// Handle type selection from more options
    func selectFromMoreOptions(_ template: QRTypeTemplate) {
        showMoreTypes = false

        // Small delay to let sheet dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.selectType(template)
        }
    }
}

// MARK: - More Button Template

extension CreateViewModel {
    /// Fake template for "More" button in grid
    var moreButtonTemplate: QRTypeTemplate {
        QRTypeTemplate(
            id: "more",
            type: .text(content: ""),
            isPremium: false
        )
    }
}
