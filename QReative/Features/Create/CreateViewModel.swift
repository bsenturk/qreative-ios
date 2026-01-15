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
    let primaryTemplates: [QRTypeTemplate] = [
        QRTypeTemplate(id: "website", type: .website(url: ""), isPremium: false),
        QRTypeTemplate(id: "wifi", type: .wifi(ssid: "", password: "", security: .wpa), isPremium: true),
        QRTypeTemplate(id: "instagram", type: .instagram(username: ""), isPremium: true),
        QRTypeTemplate(id: "whatsapp", type: .whatsapp(number: ""), isPremium: true),
        QRTypeTemplate(id: "text", type: .text(content: ""), isPremium: true),
        QRTypeTemplate(id: "vcard", type: .vcard(name: "", phone: nil, email: nil, company: nil), isPremium: true),
    ]

    let additionalTemplates: [QRTypeTemplate] = [
        QRTypeTemplate(id: "email", type: .email(address: "", subject: nil, body: nil), isPremium: true),
        QRTypeTemplate(id: "phone", type: .phone(number: ""), isPremium: true),
        QRTypeTemplate(id: "sms", type: .sms(number: "", message: nil), isPremium: true),
    ]

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
    func selectType(_ template: QRTypeTemplate) {
        if template.isPremium && !(coordinator?.isPremiumUser ?? false) {
            coordinator?.showPaywall()
            return
        }

        selectedType = template

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        tabCoordinator?.pushToCreate(.qrEditor(qrTypeId: template.id))
    }

    func showMoreOptions() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        showMoreTypes = true
    }

    func dismissMoreOptions() {
        showMoreTypes = false
    }

    func selectFromMoreOptions(_ template: QRTypeTemplate) {
        showMoreTypes = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.selectType(template)
        }
    }
}

// MARK: - More Button Template
extension CreateViewModel {
    var moreButtonTemplate: QRTypeTemplate {
        QRTypeTemplate(
            id: "more",
            type: .text(content: ""),
            isPremium: false
        )
    }
}
