import AVFoundation
import SwiftUI
import Combine

// MARK: - Camera Service

@MainActor
final class CameraService: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isAuthorized: Bool = false
    @Published var isSessionRunning: Bool = false
    @Published var detectedQRCode: String?
    @Published var torchMode: AVCaptureDevice.TorchMode = .off
    @Published var zoomFactor: CGFloat = 1.0
    @Published var error: CameraError?

    // MARK: - AVCapture Properties

    let captureSession = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let metadataOutput = AVCaptureMetadataOutput()
    private let sessionQueue = DispatchQueue(label: "com.qreative.camera.session")

    // MARK: - Configuration

    private var shouldStopOnDetection: Bool = true
    private var lastDetectedCode: String?
    private var lastDetectionTime: Date?
    private let detectionCooldown: TimeInterval = 1.0

    // MARK: - Camera Error

    enum CameraError: LocalizedError {
        case notAuthorized
        case configurationFailed
        case deviceNotAvailable
        case torchNotAvailable

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Camera access not authorized"
            case .configurationFailed:
                return "Failed to configure camera"
            case .deviceNotAvailable:
                return "Camera device not available"
            case .torchNotAvailable:
                return "Torch not available on this device"
            }
        }
    }

    // MARK: - Init

    override init() {
        super.init()
        checkInitialPermission()
    }

    // MARK: - Permission

    private func checkInitialPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        isAuthorized = status == .authorized
    }

    /// Check current camera permission status
    func checkPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            isAuthorized = true
            return true

        case .notDetermined:
            return await requestPermission()

        case .denied, .restricted:
            isAuthorized = false
            error = .notAuthorized
            return false

        @unknown default:
            isAuthorized = false
            return false
        }
    }

    /// Request camera permission
    func requestPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            isAuthorized = granted
            if !granted {
                error = .notAuthorized
            }
        }
        return granted
    }

    // MARK: - Session Setup

    /// Configure the capture session
    func setupSession() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    private func configureSession() {
        guard isAuthorized else {
            Task { @MainActor in
                error = .notAuthorized
            }
            return
        }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            Task { @MainActor in
                error = .deviceNotAvailable
            }
            captureSession.commitConfiguration()
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                videoDeviceInput = videoInput
            } else {
                Task { @MainActor in
                    error = .configurationFailed
                }
                captureSession.commitConfiguration()
                return
            }
        } catch {
            Task { @MainActor in
                self.error = .configurationFailed
            }
            captureSession.commitConfiguration()
            return
        }

        // Add metadata output for QR code detection
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

            if metadataOutput.availableMetadataObjectTypes.contains(.qr) {
                metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417, .aztec, .dataMatrix]
            }
        } else {
            Task { @MainActor in
                error = .configurationFailed
            }
            captureSession.commitConfiguration()
            return
        }

        captureSession.commitConfiguration()
    }

    // MARK: - Session Control

    /// Start the capture session
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if !self.captureSession.isRunning {
                self.captureSession.startRunning()

                Task { @MainActor in
                    self.isSessionRunning = true
                    self.detectedQRCode = nil
                    self.lastDetectedCode = nil
                }
            }
        }
    }

    /// Stop the capture session
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if self.captureSession.isRunning {
                self.captureSession.stopRunning()

                Task { @MainActor in
                    self.isSessionRunning = false
                }
            }
        }
    }

    /// Resume scanning after detection
    func resumeScanning() {
        detectedQRCode = nil
        lastDetectedCode = nil
        startSession()
    }

    // MARK: - Torch Control

    /// Toggle torch on/off
    func toggleTorch() {
        guard let device = videoDeviceInput?.device,
              device.hasTorch else {
            error = .torchNotAvailable
            return
        }

        sessionQueue.async { [weak self] in
            do {
                try device.lockForConfiguration()

                let newMode: AVCaptureDevice.TorchMode = device.torchMode == .on ? .off : .on

                if device.isTorchModeSupported(newMode) {
                    device.torchMode = newMode

                    Task { @MainActor in
                        self?.torchMode = newMode
                    }
                }

                device.unlockForConfiguration()
            } catch {
                Task { @MainActor in
                    self?.error = .torchNotAvailable
                }
            }
        }
    }

    /// Set torch mode explicitly
    func setTorch(_ mode: AVCaptureDevice.TorchMode) {
        guard let device = videoDeviceInput?.device,
              device.hasTorch,
              device.isTorchModeSupported(mode) else {
            return
        }

        sessionQueue.async { [weak self] in
            do {
                try device.lockForConfiguration()
                device.torchMode = mode
                device.unlockForConfiguration()

                Task { @MainActor in
                    self?.torchMode = mode
                }
            } catch {
                // Silently fail
            }
        }
    }

    // MARK: - Zoom Control

    /// Set zoom factor
    func setZoom(_ factor: CGFloat) {
        guard let device = videoDeviceInput?.device else { return }

        let minZoom: CGFloat = 1.0
        let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 5.0)
        let clampedFactor = max(minZoom, min(factor, maxZoom))

        sessionQueue.async { [weak self] in
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = clampedFactor
                device.unlockForConfiguration()

                Task { @MainActor in
                    self?.zoomFactor = clampedFactor
                }
            } catch {
                // Silently fail
            }
        }
    }

    /// Increase zoom
    func zoomIn() {
        setZoom(zoomFactor + 0.5)
    }

    /// Decrease zoom
    func zoomOut() {
        setZoom(zoomFactor - 0.5)
    }

    // MARK: - Configuration

    /// Configure whether to stop scanning on detection
    func setShouldStopOnDetection(_ stop: Bool) {
        shouldStopOnDetection = stop
    }

    // MARK: - Cleanup

    func cleanup() {
        stopSession()
        setTorch(.off)
    }

    deinit {
        // Note: cleanup should be called before deinit on MainActor
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension CameraService: AVCaptureMetadataOutputObjectsDelegate {

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }

        Task { @MainActor in
            handleDetectedCode(stringValue)
        }
    }

    @MainActor
    private func handleDetectedCode(_ code: String) {
        // Cooldown check to prevent rapid-fire detections
        if let lastTime = lastDetectionTime,
           let lastCode = lastDetectedCode,
           lastCode == code,
           Date().timeIntervalSince(lastTime) < detectionCooldown {
            return
        }

        lastDetectedCode = code
        lastDetectionTime = Date()
        detectedQRCode = code

        // Haptic feedback
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        // Stop session if configured
        if shouldStopOnDetection {
            stopSession()
        }
    }
}

// MARK: - Camera Preview UIViewRepresentable

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        context.coordinator.previewLayer = previewLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
