import SwiftUI
import AVFoundation

// MARK: - Preview View (UIKit)

final class PreviewView: UIView {

    // MARK: - Layer Class Override

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    // MARK: - Preview Layer

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    // MARK: - Session

    var session: AVCaptureSession? {
        get { previewLayer.session }
        set { previewLayer.session = newValue }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    // MARK: - Setup

    private func setupLayer() {
        backgroundColor = .black
        previewLayer.videoGravity = .resizeAspectFill
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        // Layer automatically resizes with view due to layerClass override
    }
}

// MARK: - Camera Preview (SwiftUI)

struct CameraPreview: UIViewRepresentable {
    let cameraService: CameraService

    // MARK: - Configuration

    var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    var cornerRadius: CGFloat = 0

    func makeUIView(context: Context) -> PreviewView {
        let previewView = PreviewView()
        previewView.session = cameraService.captureSession
        previewView.previewLayer.videoGravity = videoGravity

        if cornerRadius > 0 {
            previewView.layer.cornerRadius = cornerRadius
            previewView.clipsToBounds = true
        }

        return previewView
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Update session if changed
        if uiView.session !== cameraService.captureSession {
            uiView.session = cameraService.captureSession
        }

        // Update video gravity
        uiView.previewLayer.videoGravity = videoGravity

        // Update corner radius
        if cornerRadius > 0 {
            uiView.layer.cornerRadius = cornerRadius
            uiView.clipsToBounds = true
        } else {
            uiView.layer.cornerRadius = 0
            uiView.clipsToBounds = false
        }
    }

    // MARK: - Modifiers

    func videoGravity(_ gravity: AVLayerVideoGravity) -> CameraPreview {
        var preview = self
        preview.videoGravity = gravity
        return preview
    }

    func cornerRadius(_ radius: CGFloat) -> CameraPreview {
        var preview = self
        preview.cornerRadius = radius
        return preview
    }
}

// MARK: - Camera Preview with Overlay

struct CameraPreviewWithOverlay<Overlay: View>: View {
    let cameraService: CameraService
    let overlay: () -> Overlay

    init(
        cameraService: CameraService,
        @ViewBuilder overlay: @escaping () -> Overlay
    ) {
        self.cameraService = cameraService
        self.overlay = overlay
    }

    var body: some View {
        ZStack {
            CameraPreview(cameraService: cameraService)
                .ignoresSafeArea()

            overlay()
        }
    }
}

// MARK: - Convenience Extension

extension CameraPreview {

    /// Create a full-screen camera preview
    static func fullScreen(cameraService: CameraService) -> some View {
        CameraPreview(cameraService: cameraService)
            .ignoresSafeArea()
    }

    /// Create a camera preview with rounded corners
    static func rounded(
        cameraService: CameraService,
        cornerRadius: CGFloat = 20
    ) -> some View {
        CameraPreview(cameraService: cameraService)
            .cornerRadius(cornerRadius)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: 20) {
            // Simulated preview placeholder
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.backgroundTertiary)
                .aspectRatio(3/4, contentMode: .fit)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.accentPrimary)

                        Text("Camera Preview")
                            .typography(.body, color: .textSecondary)
                    }
                }
                .padding(.horizontal, 20)

            Text("CameraPreview requires device")
                .typography(.caption1, color: .textTertiary)
        }
    }
}
