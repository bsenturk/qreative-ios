import SwiftUI
import PhotosUI
import CoreImage
import Combine
import AudioToolbox

// MARK: - Scan Result
struct ScanResult: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let type: ScanResultType
    let symbology: CodeSymbology
    let timestamp: Date

    init(content: String, symbology: CodeSymbology = .qr) {
        self.content = content
        self.type = ScanResultType.detect(from: content)
        self.symbology = symbology
        self.timestamp = Date()
    }
}

enum ScanResultType {
    case url
    case email
    case phone
    case sms
    case wifi
    case instagram
    case whatsapp
    case contact
    case text

    var icon: String {
        switch self {
        case .url: return "globe"
        case .email: return "envelope.fill"
        case .phone: return "phone.fill"
        case .sms: return "message.fill"
        case .wifi: return "wifi"
        case .instagram: return "camera.circle.fill"
        case .whatsapp: return "message.circle.fill"
        case .contact: return "person.crop.rectangle.fill"
        case .text: return "doc.text.fill"
        }
    }

    var title: String {
        switch self {
        case .url: return appLocalized("Website")
        case .email: return appLocalized("Email")
        case .phone: return appLocalized("Phone")
        case .sms: return "SMS"
        case .wifi: return "WiFi"
        case .instagram: return "Instagram"
        case .whatsapp: return "WhatsApp"
        case .contact: return appLocalized("Contact")
        case .text: return appLocalized("Text")
        }
    }

    var analyticsName: String {
        switch self {
        case .url: return "url"
        case .email: return "email"
        case .phone: return "phone"
        case .sms: return "sms"
        case .wifi: return "wifi"
        case .instagram: return "instagram"
        case .whatsapp: return "whatsapp"
        case .contact: return "contact"
        case .text: return "text"
        }
    }

    var actionTitle: String {
        switch self {
        case .url: return appLocalized("Open URL")
        case .email: return appLocalized("Send Email")
        case .phone: return appLocalized("Call")
        case .sms: return appLocalized("Send Message")
        case .wifi: return appLocalized("Connect")
        case .instagram: return appLocalized("Open in Instagram")
        case .whatsapp: return appLocalized("Open in WhatsApp")
        case .contact: return appLocalized("Add Contact")
        case .text: return appLocalized("Copy")
        }
    }

    static func detect(from content: String) -> ScanResultType {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        // Explicit URI schemes / formats first.
        if lower.hasPrefix("begin:vcard") { return .contact }
        if lower.hasPrefix("wifi:") { return .wifi }
        if lower.hasPrefix("mailto:") { return .email }
        if lower.hasPrefix("tel:") { return .phone }
        if lower.hasPrefix("sms:") || lower.hasPrefix("smsto:") { return .sms }

        // App-specific links (checked before the generic URL rule).
        if lower.contains("instagram.com") { return .instagram }
        if lower.contains("wa.me/") || lower.contains("api.whatsapp.com") || lower.contains("whatsapp.com/send") {
            return .whatsapp
        }

        if lower.hasPrefix("http://") || lower.hasPrefix("https://") || lower.hasPrefix("www.") {
            return .url
        }

        // Scheme-less heuristics.
        if isEmailLike(trimmed) { return .email }
        if isURLLike(trimmed) { return .url }
        if isPhoneLike(trimmed) { return .phone }

        return .text
    }

    /// `name@host.tld` with no spaces.
    private static func isEmailLike(_ s: String) -> Bool {
        guard !s.contains(" "), s.contains("@") else { return false }
        let parts = s.split(separator: "@")
        return parts.count == 2 && parts[1].contains(".")
    }

    /// A bare domain like `google.com` or `sub.domain.co.uk/path` — no spaces,
    /// a dotted host, and a letters-only TLD of 2+ chars.
    private static func isURLLike(_ s: String) -> Bool {
        guard !s.contains(" "), !s.contains("@"), s.contains(".") else { return false }
        let host = s.split(separator: "/").first.map(String.init) ?? s
        let labels = host.split(separator: ".")
        guard labels.count >= 2, let tld = labels.last else { return false }
        return tld.count >= 2 && tld.allSatisfy(\.isLetter)
    }

    /// Digits (with common separators) and at least 7 actual digits.
    private static func isPhoneLike(_ s: String) -> Bool {
        let allowed: Set<Character> = ["+", "-", " ", "(", ")"]
        guard s.allSatisfy({ $0.isNumber || allowed.contains($0) }) else { return false }
        return s.filter(\.isNumber).count >= 7
    }
}

// MARK: - Scan ViewModel
@MainActor
final class ScanViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var isFlashOn: Bool = false
    @Published var zoomLevel: CGFloat = 1.0
    @Published var scanResult: ScanResult?
    @Published var showResult: Bool = false
    @Published var showPermissionAlert: Bool = false
    @Published var showGalleryPicker: Bool = false
    @Published var isProcessingImage: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isCameraAuthorized: Bool = false

    // MARK: - Camera Service
    let cameraService: CameraService

    // MARK: - Dependencies
    private weak var coordinator: AppCoordinator?

    // MARK: - Private Properties
    private var hasAppeared: Bool = false

    // MARK: - Init
    init(cameraService: CameraService) {
        self.cameraService = cameraService
        self.isCameraAuthorized = cameraService.isAuthorized
        setupBindings()
    }

    convenience init() {
        self.init(cameraService: CameraService())
    }

    // MARK: - Coordinator Binding
    func bind(coordinator: AppCoordinator?) {
        self.coordinator = coordinator
    }

    // MARK: - Setup
    private func setupBindings() {
        cameraService.$detectedCode
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detected in
                self?.handleDetectedCode(detected.value, symbology: detected.symbology)
            }
            .store(in: &cancellables)

        cameraService.$torchMode
            .map { $0 == .on }
            .receive(on: DispatchQueue.main)
            .assign(to: &$isFlashOn)

        cameraService.$zoomFactor
            .receive(on: DispatchQueue.main)
            .assign(to: &$zoomLevel)

        cameraService.$isAuthorized
            .receive(on: DispatchQueue.main)
            .assign(to: &$isCameraAuthorized)
    }

    private var cancellables = Set<AnyCancellable>()

    /// Whether the Scan screen is the active surface. When false, late camera
    /// detections are ignored so a result sheet can't pop over another tab.
    private var isActive: Bool = false

    // MARK: - Lifecycle
    func onAppear() {
        isActive = true

        if cameraService.isAuthorized {
            if scanResult == nil {
                cameraService.startSession()
            }
            return
        }

        guard !hasAppeared else { return }
        hasAppeared = true

        Task {
            let authorized = await cameraService.checkPermission()
            if authorized {
                cameraService.setupSession()
            } else {
                showPermissionAlert = true
            }
        }
    }

    func onDisappear() {
        isActive = false
        cameraService.stopSession()
        cameraService.setTorch(.off)
    }

    // MARK: - Scan Mode
    func setScanMode(_ mode: ScanMode) {
        cameraService.setScanMode(mode)
    }

    // MARK: - Camera Controls
    func toggleFlash() {
        cameraService.toggleTorch()

        HapticManager.shared.impact(.light)
    }

    func setZoom(_ level: CGFloat) {
        cameraService.setZoom(level)
    }

    // MARK: - Detection Handling
    private func handleDetectedCode(_ code: String, symbology: CodeSymbology) {
        guard isActive, scanResult == nil else { return }

        let result = ScanResult(content: code, symbology: symbology)
        scanResult = result
        showResult = true

        playScanSound()
        AnalyticsService.qrScanned(resultType: result.type.analyticsName, source: "camera")
        ReviewManager.registerScanAndRequestReviewIfNeeded()

        saveToHistory()
        autoOpenIfNeeded(result)
    }

    // MARK: - Gallery Processing
    func processGalleryImage(_ image: UIImage) {
        isProcessingImage = true

        Task {
            defer { isProcessingImage = false }

            guard let ciImage = CIImage(image: image) else {
                AnalyticsService.scanFailed(source: "photo", reason: "invalid_image")
                showError(message: appLocalized("Failed to process image"))
                return
            }

            let detector = CIDetector(
                ofType: CIDetectorTypeQRCode,
                context: nil,
                options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            )

            guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature],
                  let qrFeature = features.first,
                  let messageString = qrFeature.messageString else {
                AnalyticsService.scanFailed(source: "photo", reason: "no_qr_found")
                showError(message: appLocalized("No QR code found in image"))
                return
            }

            // Directly set the result for gallery scans to ensure history is saved
            let result = ScanResult(content: messageString)
            scanResult = result
            showResult = true
            playScanSound()
            AnalyticsService.qrScanned(resultType: result.type.analyticsName, source: "photo")
            ReviewManager.registerScanAndRequestReviewIfNeeded()
            saveToHistory()
            autoOpenIfNeeded(result)
        }
    }

    // MARK: - Scan Feedback
    /// System sound ID for the scan tone. Uses a bundled `scan.{caf,wav,aiff}`
    /// file if one is present, otherwise falls back to a built-in iOS tone.
    /// Loaded once and cached.
    private static let scanSoundID: SystemSoundID = {
        for ext in ["caf", "wav", "aiff", "aif"] {
            if let url = Bundle.main.url(forResource: "scan", withExtension: ext) {
                var soundID: SystemSoundID = 0
                AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
                return soundID
            }
        }
        return 1057 // built-in "Tink" fallback
    }()

    /// Plays a short scan tone when "Scan sound" is enabled.
    private func playScanSound() {
        guard AppSettings.shared.scanSoundEnabled else { return }
        AudioServicesPlaySystemSound(Self.scanSoundID)
    }

    /// Opens link-type results immediately when "Auto-open links" is enabled.
    private func autoOpenIfNeeded(_ result: ScanResult) {
        guard AppSettings.shared.autoOpenLinks else { return }
        switch result.type {
        case .url, .instagram, .whatsapp:
            openURL()
        default:
            break
        }
    }

    // MARK: - Result Actions
    func copyToClipboard() {
        guard let result = scanResult else { return }

        UIPasteboard.general.string = result.content
        AnalyticsService.scanResultAction("copy", resultType: result.type.analyticsName)

        HapticManager.shared.success()
    }

    func shareCode() {
    }

    func openURL() {
        guard let content = scanResult?.content else { return }

        var urlString = content

        switch scanResult?.type {
        case .url, .instagram, .whatsapp:
            // Scheme-less domains (e.g. "www.google.com", "instagram.com/x")
            // need a scheme to open. The https link opens the matching app via
            // universal links when it's installed.
            if !urlString.lowercased().hasPrefix("http://"),
               !urlString.lowercased().hasPrefix("https://") {
                urlString = "https://\(urlString)"
            }
        case .email:
            if !urlString.lowercased().hasPrefix("mailto:") {
                urlString = "mailto:\(urlString)"
            }
        case .phone:
            if !urlString.lowercased().hasPrefix("tel:") {
                urlString = "tel:\(urlString.replacingOccurrences(of: " ", with: ""))"
            }
        case .sms:
            // Content is already an "sms:"/"smsto:" URL; open Messages as-is.
            break
        default:
            // .wifi / .contact / .text have no URL action (contact is handled
            // by the contact-card sheet in the view).
            return
        }

        guard let url = URL(string: urlString) else { return }

        if let result = scanResult {
            AnalyticsService.scanResultAction("open_url", resultType: result.type.analyticsName)
        }
        UIApplication.shared.open(url)
    }

    func saveToHistory() {
        guard let result = scanResult else { return }

        // Convert ScanResultType to HistoryItemType
        let historyType: HistoryItemType = {
            switch result.type {
            case .url:
                return .website
            case .email:
                return .email
            case .phone:
                return .phone
            case .sms:
                return .sms
            case .wifi:
                return .wifi
            case .instagram:
                return .instagram
            case .whatsapp:
                return .whatsapp
            case .contact:
                return .vcard
            case .text:
                return .text
            }
        }()

        let historyItem = HistoryItem(
            content: result.content,
            type: historyType,
            createdAt: result.timestamp,
            source: .scanned,
            symbology: result.symbology
        )

        Task {
            try? await StorageService.shared.saveItem(historyItem)
        }
    }

    // MARK: - Result Management
    /// Closes the result sheet. Actual cleanup happens in
    /// `handleResultDismissed()`, which the sheet calls on dismiss — so it runs
    /// whether the user taps the button or swipes the sheet down.
    func dismissResult() {
        showResult = false
    }

    /// Called whenever the result sheet finishes dismissing (button or swipe).
    /// Clears the result and resumes scanning so the camera doesn't stay frozen.
    func handleResultDismissed() {
        scanResult = nil
        cameraService.resumeScanning()

        // First successful scan is the "aha" moment — present the deferred paywall once.
        coordinator?.maybeShowActivationPaywall()
    }

    func rescan() {
        dismissResult()
    }

    // MARK: - Settings
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }

    // MARK: - Error Handling
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
