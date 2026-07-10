import SwiftUI
import Combine

// MARK: - Create ViewModel
@MainActor
final class CreateViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var selectedType: QRTypeTemplate?
    @Published var navigateToEditor: Bool = false

    // MARK: - Properties
    let primaryTemplates: [QRTypeTemplate] = [
        QRTypeTemplate(id: "website", type: .website(url: ""), isPremium: false),
        QRTypeTemplate(id: "wifi", type: .wifi(ssid: "", password: "", security: .wpa), isPremium: true),
        QRTypeTemplate(id: "instagram", type: .instagram(username: ""), isPremium: true),
        QRTypeTemplate(id: "whatsapp", type: .whatsapp(number: ""), isPremium: true),
        QRTypeTemplate(id: "x", type: .x(username: ""), isPremium: true),
        QRTypeTemplate(id: "tiktok", type: .tiktok(username: ""), isPremium: true),
        QRTypeTemplate(id: "text", type: .text(content: ""), isPremium: true),
        QRTypeTemplate(id: "vcard", type: .vcard(name: "", phone: nil, email: nil, company: nil), isPremium: true),
        QRTypeTemplate(id: "email", type: .email(address: "", subject: nil, body: nil), isPremium: true),
        QRTypeTemplate(id: "phone", type: .phone(number: ""), isPremium: true),
        QRTypeTemplate(id: "sms", type: .sms(number: "", message: nil), isPremium: true),
    ]

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
            AnalyticsService.premiumGateHit(feature: "qr_type_\(template.id)")
            coordinator?.showPaywall(source: "create_qr_type")
            return
        }

        AnalyticsService.qrTypeSelected(template.id)
        selectedType = template

        HapticManager.shared.impact(.medium)

        tabCoordinator?.pushToCreate(.qrEditor(qrTypeId: template.id))
    }

}
