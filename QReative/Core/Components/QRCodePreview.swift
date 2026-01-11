import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - QR Shape

enum QRShape: String, CaseIterable {
    case squares
    case dots
    case rounded

    var displayName: String {
        switch self {
        case .squares: return "Square"
        case .dots: return "Dots"
        case .rounded: return "Rounded"
        }
    }

    var icon: String {
        switch self {
        case .squares: return "square.fill"
        case .dots: return "circle.fill"
        case .rounded: return "square.fill"
        }
    }
}

// MARK: - QR Code Preview

struct QRCodePreview: View {
    let content: String
    let size: CGFloat
    let foregroundColor: Color
    let backgroundColor: Color
    let shape: QRShape
    let logoImage: UIImage?
    let isGlowing: Bool

    @State private var qrMatrix: [[Bool]] = []

    init(
        content: String,
        size: CGFloat = 200,
        foregroundColor: Color = .accentPrimary,
        backgroundColor: Color = .white,
        shape: QRShape = .squares,
        logoImage: UIImage? = nil,
        isGlowing: Bool = false
    ) {
        self.content = content
        self.size = size
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.shape = shape
        self.logoImage = logoImage
        self.isGlowing = isGlowing
    }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)

            // QR Code
            if !qrMatrix.isEmpty {
                qrCodeView
                    .padding(size * 0.1)
            } else {
                ProgressView()
                    .tint(foregroundColor)
            }

            // Logo overlay
            if let logo = logoImage {
                logoView(logo)
            }
        }
        .frame(width: size, height: size)
        .shadow(
            color: isGlowing ? foregroundColor.opacity(0.5) : .clear,
            radius: isGlowing ? 20 : 0,
            x: 0,
            y: 0
        )
        .onAppear {
            generateQRMatrix()
        }
        .onChange(of: content) { _, _ in
            generateQRMatrix()
        }
    }

    // MARK: - QR Code View

    @ViewBuilder
    private var qrCodeView: some View {
        let moduleCount = qrMatrix.count
        let moduleSize = (size * 0.8) / CGFloat(moduleCount)
        let logoRadius = logoImage != nil ? Int(Double(moduleCount) * 0.25) : 0
        let center = moduleCount / 2

        Canvas { context, canvasSize in
            let scale = canvasSize.width / (size * 0.8)

            for row in 0..<moduleCount {
                for col in 0..<moduleCount {
                    guard qrMatrix[row][col] else { continue }

                    // Skip center area for logo
                    if logoImage != nil {
                        let distanceFromCenter = max(abs(row - center), abs(col - center))
                        if distanceFromCenter < logoRadius {
                            continue
                        }
                    }

                    let x = CGFloat(col) * moduleSize * scale
                    let y = CGFloat(row) * moduleSize * scale
                    let rect = CGRect(x: x, y: y, width: moduleSize * scale, height: moduleSize * scale)

                    let path = modulePath(for: rect)
                    context.fill(path, with: .color(foregroundColor))
                }
            }
        }
    }

    // MARK: - Module Path

    private func modulePath(for rect: CGRect) -> Path {
        let inset: CGFloat = rect.width * 0.05

        switch shape {
        case .squares:
            return Path(rect.insetBy(dx: inset, dy: inset))

        case .dots:
            let diameter = min(rect.width, rect.height) - (inset * 2)
            let circleRect = CGRect(
                x: rect.midX - diameter / 2,
                y: rect.midY - diameter / 2,
                width: diameter,
                height: diameter
            )
            return Path(ellipseIn: circleRect)

        case .rounded:
            let cornerRadius = rect.width * 0.3
            return Path(
                roundedRect: rect.insetBy(dx: inset, dy: inset),
                cornerRadius: cornerRadius
            )
        }
    }

    // MARK: - Logo View

    @ViewBuilder
    private func logoView(_ logo: UIImage) -> some View {
        let logoSize = size * 0.22

        ZStack {
            // White background circle
            Circle()
                .fill(.white)
                .frame(width: logoSize + 8, height: logoSize + 8)

            // Logo image
            Image(uiImage: logo)
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
                .clipShape(Circle())
        }
    }

    // MARK: - QR Generation

    private func generateQRMatrix() {
        guard !content.isEmpty else {
            qrMatrix = []
            return
        }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(content.utf8)
        filter.correctionLevel = logoImage != nil ? "H" : "M"

        guard let outputImage = filter.outputImage else {
            qrMatrix = []
            return
        }

        // Get pixel data
        let size = Int(outputImage.extent.width)
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            qrMatrix = []
            return
        }

        // Create bitmap context to read pixels
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            qrMatrix = []
            return
        }

        var matrix: [[Bool]] = Array(
            repeating: Array(repeating: false, count: size),
            count: size
        )

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        for row in 0..<size {
            for col in 0..<size {
                let offset = row * bytesPerRow + col * bytesPerPixel
                // QR code: black = 0, white = 255
                matrix[row][col] = bytes[offset] == 0
            }
        }

        qrMatrix = matrix
    }
}

// MARK: - Static Generator

extension QRCodePreview {
    /// Generate QR code as UIImage
    static func generateImage(
        content: String,
        size: CGFloat = 512,
        foregroundColor: UIColor = .black,
        backgroundColor: UIColor = .white
    ) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(content.utf8)
        filter.correctionLevel = "H"

        guard let outputImage = filter.outputImage else { return nil }

        // Scale up
        let scale = size / outputImage.extent.width
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Apply colors
        let colorFilter = CIFilter.falseColor()
        colorFilter.inputImage = scaledImage
        colorFilter.color0 = CIColor(color: foregroundColor)
        colorFilter.color1 = CIColor(color: backgroundColor)

        guard let coloredImage = colorFilter.outputImage,
              let cgImage = context.createCGImage(coloredImage, from: coloredImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                // Default
                QRCodePreview(content: "https://qreative.app")

                // With glow
                QRCodePreview(
                    content: "https://qreative.app",
                    foregroundColor: .accentPrimary,
                    isGlowing: true
                )

                // Dots shape
                QRCodePreview(
                    content: "Hello World",
                    size: 180,
                    foregroundColor: .accentTertiary,
                    shape: .dots
                )

                // Rounded shape
                QRCodePreview(
                    content: "QReative",
                    size: 180,
                    foregroundColor: .accentSecondary,
                    shape: .rounded
                )

                // All shapes
                HStack(spacing: 16) {
                    ForEach(QRShape.allCases, id: \.self) { shape in
                        VStack(spacing: 8) {
                            QRCodePreview(
                                content: "Test",
                                size: 100,
                                shape: shape
                            )
                            Text(shape.displayName)
                                .typography(.caption2, color: .textSecondary)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}
