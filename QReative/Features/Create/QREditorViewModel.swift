import SwiftUI
import Combine

// MARK: - QR Color
enum QRColor: String, CaseIterable, Identifiable {
    // Solids
    case black
    case cobalt
    case red
    case green
    case purple
    // Gradients
    case sunset
    case ocean
    case forest
    case grape

    var id: String { rawValue }

    /// Only black is free; every other color requires PRO.
    var isPremium: Bool { self != .black }

    var displayName: String {
        switch self {
        case .black: return "Black"
        case .cobalt: return "Cobalt"
        case .red: return "Red"
        case .green: return "Green"
        case .purple: return "Purple"
        case .sunset: return "Sunset"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .grape: return "Grape"
        }
    }

    var colors: [Color] {
        switch self {
        case .black: return [.black]
        case .cobalt: return [Color(hex: "3457C8")]
        case .red: return [Color(hex: "E03131")]
        case .green: return [Color(hex: "2F9E44")]
        case .purple: return [Color(hex: "7048E8")]
        case .sunset: return [Color(hex: "FF8A00"), Color(hex: "FF2D78")]
        case .ocean: return [Color(hex: "0091FF"), Color(hex: "00D4FF")]
        case .forest: return [Color(hex: "0B8043"), Color(hex: "7CB342")]
        case .grape: return [Color(hex: "7048E8"), Color(hex: "E64980")]
        }
    }

    var isGradient: Bool { colors.count > 1 }

    var foregroundColor: Color { colors.first ?? .black }

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

    @Published var selectedColor: QRColor = .black
    @Published var selectedShape: QRShape = .squares
    @Published var logoImage: UIImage?
    @Published var selectedEmoji: String?
    @Published var showLogoPicker: Bool = false
    @Published var showEmojiPicker: Bool = false
    @Published var showPaywall: Bool = false
    @Published var isSaving: Bool = false
    @Published var isLoadingLogo: Bool = false
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

    var isPremiumUser: Bool {
        coordinator?.isPremiumUser ?? false
    }

    var canAddLogo: Bool {
        isPremiumUser
    }

    var canAddEmoji: Bool {
        isPremiumUser
    }

    /// The center overlay drawn on the QR code: a picked logo, or a rendered emoji.
    var overlayImage: UIImage? {
        if let logoImage { return logoImage }
        if let selectedEmoji { return Self.renderEmoji(selectedEmoji) }
        return nil
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
        case .whatsapp:
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

    // MARK: - Paywall Trigger
    /// Logs which locked feature drove the upgrade prompt, then presents the paywall.
    private func triggerPaywall(feature: String) {
        AnalyticsService.premiumGateHit(feature: feature)
        AnalyticsService.paywallShown(source: "editor_\(feature)")
        showPaywall = true
    }

    func logoGateTapped() {
        triggerPaywall(feature: "logo")
    }

    // MARK: - Color Selection
    func selectColor(_ color: QRColor) {
        guard selectedColor != color else { return }

        if color.isPremium && !isPremiumUser {
            triggerPaywall(feature: "color")
            return
        }

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(Theme.animation.spring) {
            selectedColor = color
        }
    }

    // MARK: - Shape Selection
    func selectShape(_ shape: QRShape) {
        guard selectedShape != shape else { return }

        if shape.isPremium && !isPremiumUser {
            triggerPaywall(feature: "shape")
            return
        }

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(Theme.animation.spring) {
            selectedShape = shape
        }
    }

    // MARK: - Logo
    func addLogo(_ image: UIImage) {
        guard canAddLogo else {
            triggerPaywall(feature: "logo")
            return
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        withAnimation(Theme.animation.spring) {
            logoImage = image
            selectedEmoji = nil   // logo and emoji are mutually exclusive
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
            triggerPaywall(feature: "logo")
        }
    }

    // MARK: - Emoji
    func requestAddEmoji() {
        if canAddEmoji {
            showEmojiPicker = true
        } else {
            triggerPaywall(feature: "emoji")
        }
    }

    func addEmoji(_ emoji: String) {
        guard canAddEmoji else {
            triggerPaywall(feature: "emoji")
            return
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        withAnimation(Theme.animation.spring) {
            selectedEmoji = emoji
            logoImage = nil   // emoji and logo are mutually exclusive
        }
    }

    func removeEmoji() {
        withAnimation(Theme.animation.spring) {
            selectedEmoji = nil
        }
    }

    /// Renders an emoji string into a transparent square image so it can be
    /// drawn as the QR center overlay (reusing the logo rendering pipeline).
    static func renderEmoji(_ emoji: String, size: CGFloat = 240) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            let font = UIFont.systemFont(ofSize: size * 0.72)
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let string = emoji as NSString
            let textSize = string.size(withAttributes: attributes)
            let rect = CGRect(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            string.draw(in: rect, withAttributes: attributes)
        }
    }

    // MARK: - Generate QR Image
    func generateQRImage(dimension: CGFloat = 512) -> UIImage? {
        let content = qrContent
        guard !content.isEmpty else { return nil }

        let size = CGSize(width: dimension, height: dimension)
        let fgColor = UIColor(selectedColor.foregroundColor)
        let bgColor = UIColor.white
        let overlay = overlayImage

        if selectedColor.isGradient {
            return qrCodeService.generateGradientQRCode(
                content: content,
                size: size,
                gradientColors: selectedColor.colors.map { UIColor($0) },
                backgroundColor: bgColor,
                shape: selectedShape,
                logo: overlay
            )
        } else {
            return qrCodeService.generateStyledQRCode(
                content: content,
                size: size,
                foregroundColor: fgColor,
                backgroundColor: bgColor,
                shape: selectedShape,
                logo: overlay
            )
        }
    }

    // MARK: - Save
    func save() async {
        guard isValid else { return }

        isSaving = true

        do {
            // Free users get a low-resolution export; PRO users get a full-HD render.
            let dimension: CGFloat = isPremiumUser ? 1080 : 480
            guard let qrImage = generateQRImage(dimension: dimension) else {
                throw NSError(domain: "QREditor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate QR code"])
            }

            generatedImage = qrImage

            try await qrCodeService.saveToPhotos(qrImage)

            let historyType = HistoryItemType(rawValue: template.id) ?? .unknown
            let historyItem = HistoryItem(
                content: qrContent,
                type: historyType,
                customColor: selectedColor.rawValue,
                customShape: selectedShape.rawValue,
                hasLogo: logoImage != nil || selectedEmoji != nil
            )
            try await storageService.saveItem(historyItem)

            AnalyticsService.qrCreated(
                type: template.id,
                color: selectedColor.rawValue,
                shape: selectedShape.rawValue,
                hasLogo: logoImage != nil,
                hasEmoji: selectedEmoji != nil,
                isPremium: isPremiumUser
            )

            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

            isSaving = false

            if isPremiumUser {
                showSaveSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.tabCoordinator?.pop()
                }
            } else {
                // Free users see an interstitial ad after saving, then return.
                InterstitialAdManager.shared.showAd(isPremiumUser: false) { [weak self] in
                    self?.tabCoordinator?.pop()
                }
            }
            return

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
