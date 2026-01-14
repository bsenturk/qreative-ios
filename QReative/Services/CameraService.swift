@preconcurrency import AVFoundation
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
    nonisolated(unsafe) let captureSession = AVCaptureSession()
    nonisolated(unsafe) private var videoDeviceInput: AVCaptureDeviceInput?
    nonisolated(unsafe) private let metadataOutput = AVCaptureMetadataOutput()
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
    func setupSession() {
        let authorized = isAuthorized
        sessionQueue.async { [weak self] in
            self?.configureSession(authorized: authorized)
        }
    }

    private nonisolated func configureSession(authorized: Bool) {
        guard authorized else {
            Task { @MainActor [weak self] in
                self?.error = .notAuthorized
            }
            return
        }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            Task { @MainActor [weak self] in
                self?.error = .deviceNotAvailable
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
                Task { @MainActor [weak self] in
                    self?.error = .configurationFailed
                }
                captureSession.commitConfiguration()
                return
            }
        } catch {
            Task { @MainActor [weak self] in
                self?.error = .configurationFailed
            }
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

            if metadataOutput.availableMetadataObjectTypes.contains(.qr) {
                metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417, .aztec, .dataMatrix]
            }
        } else {
            Task { @MainActor [weak self] in
                self?.error = .configurationFailed
            }
            captureSession.commitConfiguration()
            return
        }

        captureSession.commitConfiguration()

        // Start session after configuration is complete
        if !captureSession.isRunning {
            captureSession.startRunning()

            Task { @MainActor [weak self] in
                self?.isSessionRunning = true
                self?.detectedQRCode = nil
                self?.lastDetectedCode = nil
            }
        }
    }

    // MARK: - Session Control
    func startSession() {
        let session = captureSession
        sessionQueue.async { [weak self] in
            if !session.isRunning {
                session.startRunning()

                Task { @MainActor [weak self] in
                    self?.isSessionRunning = true
                    self?.detectedQRCode = nil
                    self?.lastDetectedCode = nil
                }
            }
        }
    }

    func stopSession() {
        let session = captureSession
        sessionQueue.async { [weak self] in
            if session.isRunning {
                session.stopRunning()

                Task { @MainActor [weak self] in
                    self?.isSessionRunning = false
                }
            }
        }
    }

    func resumeScanning() {
        detectedQRCode = nil
        lastDetectedCode = nil
        startSession()
    }

    // MARK: - Torch Control
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

                    Task { @MainActor [weak self] in
                        self?.torchMode = newMode
                    }
                }

                device.unlockForConfiguration()
            } catch {
                Task { @MainActor [weak self] in
                    self?.error = .torchNotAvailable
                }
            }
        }
    }

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

                Task { @MainActor [weak self] in
                    self?.torchMode = mode
                }
            } catch {
            }
        }
    }

    // MARK: - Zoom Control
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

                Task { @MainActor [weak self] in
                    self?.zoomFactor = clampedFactor
                }
            } catch {
            }
        }
    }

    func zoomIn() {
        setZoom(zoomFactor + 0.5)
    }

    func zoomOut() {
        setZoom(zoomFactor - 0.5)
    }

    // MARK: - Configuration
    func setShouldStopOnDetection(_ stop: Bool) {
        shouldStopOnDetection = stop
    }

    // MARK: - Cleanup
    func cleanup() {
        stopSession()
        setTorch(.off)
    }

    deinit {
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
        if let lastTime = lastDetectionTime,
           let lastCode = lastDetectedCode,
           lastCode == code,
           Date().timeIntervalSince(lastTime) < detectionCooldown {
            return
        }

        lastDetectedCode = code
        lastDetectionTime = Date()
        detectedQRCode = code

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

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
