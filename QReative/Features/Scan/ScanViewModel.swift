import SwiftUI
import PhotosUI
import CoreImage

// MARK: - Scan Result

struct ScanResult: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let type: ScanResultType
    let timestamp: Date

    init(content: String) {
        self.content = content
        self.type = ScanResultType.detect(from: content)
        self.timestamp = Date()
    }
}

enum ScanResultType {
    case url
    case email
    case phone
    case wifi
    case text

    var icon: String {
        switch self {
        case .url: return "globe"
        case .email: return "envelope.fill"
        case .phone: return "phone.fill"
        case .wifi: return "wifi"
        case .text: return "doc.text.fill"
        }
    }

    var title: String {
        switch self {
        case .url: return "Website"
        case .email: return "Email"
        case .phone: return "Phone"
        case .wifi: return "WiFi"
        case .text: return "Text"
        }
    }

    var actionTitle: String {
        switch self {
        case .url: return "Open URL"
        case .email: return "Send Email"
        case .phone: return "Call"
        case .wifi: return "Connect"
        case .text: return "Copy"
        }
    }

    static func detect(from content: String) -> ScanResultType {
        if content.lowercased().hasPrefix("http://") || content.lowercased().hasPrefix("https://") {
            return .url
        } else if content.lowercased().hasPrefix("mailto:") || content.contains("@") && content.contains(".") {
            return .email
        } else if content.lowercased().hasPrefix("tel:") || content.allSatisfy({ $0.isNumber || $0 == "+" || $0 == "-" || $0 == " " }) && content.count >= 7 {
            return .phone
        } else if content.lowercased().hasPrefix("wifi:") {
            return .wifi
        }
        return .text
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

    // MARK: - Camera Service

    let cameraService: CameraService

    // MARK: - Private Properties

    private var hasAppeared: Bool = false

    // MARK: - Init

    init(cameraService: CameraService) {
        self.cameraService = cameraService
        setupBindings()
    }

    /// Convenience init that creates its own CameraService
    convenience init() {
        self.init(cameraService: CameraService())
    }

    // MARK: - Setup

    private func setupBindings() {
        // Observe camera service detected code
        cameraService.$detectedQRCode
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] code in
                self?.handleDetectedCode(code)
            }
            .store(in: &cancellables)

        // Sync flash state
        cameraService.$torchMode
            .map { $0 == .on }
            .receive(on: DispatchQueue.main)
            .assign(to: &$isFlashOn)

        // Sync zoom
        cameraService.$zoomFactor
            .receive(on: DispatchQueue.main)
            .assign(to: &$zoomLevel)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    func onAppear() {
        guard !hasAppeared else {
            // Resume if returning to view
            if cameraService.isAuthorized && scanResult == nil {
                cameraService.startSession()
            }
            return
        }

        hasAppeared = true

        Task {
            let authorized = await cameraService.checkPermission()
            if authorized {
                cameraService.setupSession()
                cameraService.startSession()
            } else {
                showPermissionAlert = true
            }
        }
    }

    func onDisappear() {
        cameraService.stopSession()
        cameraService.setTorch(.off)
    }

    // MARK: - Camera Controls

    func toggleFlash() {
        cameraService.toggleTorch()

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func setZoom(_ level: CGFloat) {
        cameraService.setZoom(level)
    }

    // MARK: - Detection Handling

    private func handleDetectedCode(_ code: String) {
        guard scanResult == nil else { return }

        scanResult = ScanResult(content: code)
        showResult = true

        // Save to history
        saveToHistory()
    }

    // MARK: - Gallery Processing

    func processGalleryImage(_ image: UIImage) {
        isProcessingImage = true

        Task {
            defer { isProcessingImage = false }

            guard let ciImage = CIImage(image: image) else {
                showError(message: "Failed to process image")
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
                showError(message: "No QR code found in image")
                return
            }

            handleDetectedCode(messageString)
        }
    }

    // MARK: - Result Actions

    func copyToClipboard() {
        guard let content = scanResult?.content else { return }

        UIPasteboard.general.string = content

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }

    func shareCode() {
        // Share is handled in View with ShareLink
    }

    func openURL() {
        guard let content = scanResult?.content else { return }

        var urlString = content

        // Handle different types
        switch scanResult?.type {
        case .url:
            break // Already a URL
        case .email:
            if !urlString.lowercased().hasPrefix("mailto:") {
                urlString = "mailto:\(urlString)"
            }
        case .phone:
            if !urlString.lowercased().hasPrefix("tel:") {
                urlString = "tel:\(urlString.replacingOccurrences(of: " ", with: ""))"
            }
        default:
            return
        }

        guard let url = URL(string: urlString) else { return }

        UIApplication.shared.open(url)
    }

    func saveToHistory() {
        guard let result = scanResult else { return }

        // TODO: Implement with StorageService
        // storageService.saveHistoryItem(result)
        print("Saved to history: \(result.content)")
    }

    // MARK: - Result Management

    func dismissResult() {
        withAnimation(Theme.animation.spring) {
            showResult = false
        }

        // Delay clearing result and resuming
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.scanResult = nil
            self?.cameraService.resumeScanning()
        }
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

// MARK: - Combine Import

import Combine
