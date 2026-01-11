import SwiftUI
import Combine

// MARK: - QR Color

enum QRColor: String, CaseIterable, Identifiable {
    case black
    case purple
    case gradient

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .black: return "Black"
        case .purple: return "Purple"
        case .gradient: return "Gradient"
        }
    }

    var foregroundColor: Color {
        switch self {
        case .black: return .black
        case .purple: return Color(hex: "6200EA")
        case .gradient: return Color(hex: "6200EA")
        }
    }

    var colors: [Color] {
        switch self {
        case .black: return [.black]
        case .purple: return [Color(hex: "6200EA"), Color(hex: "9C27B0")]
        case .gradient: return [Color(hex: "6200EA"), Color(hex: "00E5FF")]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - QR Editor ViewModel

@MainActor
final class QREditorViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var content: String = ""
    @Published var wifiSSID: String = ""
    @Published var wifiPassword: String = ""
    @Published var wifiSecurity: WifiSecurity = .wpa
    @Published var vcardName: String = ""
    @Published var vcardPhone: String = ""
    @Published var vcardEmail: String = ""
    @Published var vcardCompany: String = ""
    @Published var emailSubject: String = ""
    @Published var emailBody: String = ""
    @Published var smsMessage: String = ""

    @Published var selectedColor: QRColor = .purple
    @Published var selectedShape: QRShape = .squares
    @Published var logoImage: UIImage?
    @Published var showLogoPicker: Bool = false
    @Published var showPaywall: Bool = false
    @Published var isSaving: Bool = false
    @Published var showSaveSuccess: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Properties

    let template: QRTypeTemplate
    private(set) var generatedImage: UIImage?

    // MARK: - Dependencies

    private let qrCodeService = QRCodeService.shared
    private let storageService = StorageService()
    private weak var coordinator: AppCoordinator?
    private weak var tabCoordinator: MainTabCoordinator?

    // MARK: - Computed Properties

    var qrContent: String {
        buildQRType().generateQRContent()
    }

    var isValid: Bool {
        buildQRType().isValid
    }

    var canAddLogo: Bool {
        coordinator?.isPremiumUser ?? false
    }

    var title: String {
        template.title
    }

    var placeholder: String {
        template.type.placeholder
    }

    var foregroundColor: Color {
        selectedColor.foregroundColor
    }

    // MARK: - Init

    init(template: QRTypeTemplate) {
        self.template = template
        setupInitialContent()
    }

    convenience init(qrType: QRType) {
        let isPremium = qrType.id == "vcard" || qrType.id == "sms"
        let template = QRTypeTemplate(id: qrType.id, type: qrType, isPremium: isPremium)
        self.init(template: template)
    }

    // MARK: - Setup

    private func setupInitialContent() {
        // Set default content based on type
        switch template.type {
        case .website:
            content = ""
        case .wifi:
            wifiSSID = ""
            wifiPassword = ""
            wifiSecurity = .wpa
        case .instagram:
            content = ""
        case .text:
            content = ""
        case .vcard:
            vcardName = ""
        case .email:
            content = ""
        case .phone:
            content = ""
        case .sms:
            content = ""
        }
    }

    // MARK: - Coordinator Binding

    func bind(appCoordinator: AppCoordinator?, tabCoordinator: MainTabCoordinator?) {
        self.coordinator = appCoordinator
        self.tabCoordinator = tabCoordinator
    }

    // MARK: - Build QR Type

    private func buildQRType() -> QRType {
        switch template.id {
        case "website":
            return .website(url: content)
        case "wifi":
            return .wifi(ssid: wifiSSID, password: wifiPassword, security: wifiSecurity)
        case "instagram":
            return .instagram(username: content)
        case "text":
            return .text(content: content)
        case "vcard":
            return .vcard(
                name: vcardName,
                phone: vcardPhone.isEmpty ? nil : vcardPhone,
                email: vcardEmail.isEmpty ? nil : vcardEmail,
                company: vcardCompany.isEmpty ? nil : vcardCompany
            )
        case "email":
            return .email(
                address: content,
                subject: emailSubject.isEmpty ? nil : emailSubject,
                body: emailBody.isEmpty ? nil : emailBody
            )
        case "phone":
            return .phone(number: content)
        case "sms":
            return .sms(
                number: content,
                message: smsMessage.isEmpty ? nil : smsMessage
            )
        default:
            return .text(content: content)
        }
    }

    // MARK: - Color Selection

    func selectColor(_ color: QRColor) {
        guard selectedColor != color else { return }

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(Theme.animation.spring) {
            selectedColor = color
        }
    }

    // MARK: - Shape Selection

    func selectShape(_ shape: QRShape) {
        guard selectedShape != shape else { return }

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(Theme.animation.spring) {
            selectedShape = shape
        }
    }

    // MARK: - Logo

    func addLogo(_ image: UIImage) {
        guard canAddLogo else {
            showPaywall = true
            return
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        withAnimation(Theme.animation.spring) {
            logoImage = image
        }
    }

    func removeLogo() {
        withAnimation(Theme.animation.spring) {
            logoImage = nil
        }
    }

    func requestAddLogo() {
        if canAddLogo {
            showLogoPicker = true
        } else {
            showPaywall = true
        }
    }

    // MARK: - Generate QR Image

    func generateQRImage() -> UIImage? {
        let content = qrContent
        guard !content.isEmpty else { return nil }

        let size = CGSize(width: 512, height: 512)
        let fgColor = UIColor(selectedColor.foregroundColor)
        let bgColor = UIColor.white

        if selectedColor == .gradient {
            return qrCodeService.generateGradientQRCode(
                content: content,
                size: size,
                gradientColors: selectedColor.colors.map { UIColor($0) },
                backgroundColor: bgColor,
                shape: selectedShape,
                logo: logoImage
            )
        } else {
            return qrCodeService.generateStyledQRCode(
                content: content,
                size: size,
                foregroundColor: fgColor,
                backgroundColor: bgColor,
                shape: selectedShape,
                logo: logoImage
            )
        }
    }

    // MARK: - Save

    func save() async {
        guard isValid else { return }

        isSaving = true

        do {
            // Generate QR code image
            guard let qrImage = generateQRImage() else {
                throw NSError(domain: "QREditor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate QR code"])
            }

            generatedImage = qrImage

            // Save to photos
            try await qrCodeService.saveToPhotos(qrImage)

            // Save to history
            let historyType = HistoryItemType(rawValue: template.id) ?? .unknown
            let historyItem = HistoryItem(
                content: qrContent,
                type: historyType,
                customColor: selectedColor.rawValue,
                customShape: selectedShape.rawValue,
                hasLogo: logoImage != nil
            )
            try await storageService.saveItem(historyItem)

            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

            showSaveSuccess = true

            // Navigate back after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.tabCoordinator?.pop()
            }

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSaving = false
    }

    // MARK: - Cancel

    func cancel() {
        tabCoordinator?.pop()
    }
}
