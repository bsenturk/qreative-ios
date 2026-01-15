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
    let gradientColors: [Color]?

    @State private var qrMatrix: [[Bool]] = []

    init(
        content: String,
        size: CGFloat = 200,
        foregroundColor: Color = .accentPrimary,
        backgroundColor: Color = .white,
        shape: QRShape = .squares,
        logoImage: UIImage? = nil,
        isGlowing: Bool = false,
        gradientColors: [Color]? = nil
    ) {
        self.content = content
        self.size = size
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.shape = shape
        self.logoImage = logoImage
        self.isGlowing = isGlowing
        self.gradientColors = gradientColors
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)

            if !qrMatrix.isEmpty {
                qrCodeView
                    .padding(size * 0.1)
            } else {
                ProgressView()
                    .tint(foregroundColor)
            }

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
        // Add quiet zone (4 modules padding on each side)
        let quietZoneModules: CGFloat = 4
        let totalModules = CGFloat(moduleCount) + (quietZoneModules * 2)
        let moduleSize = (size * 0.8) / totalModules
        let offset = quietZoneModules * moduleSize
        let logoRadius = logoImage != nil ? Int(Double(moduleCount) * 0.25) : 0
        let center = moduleCount / 2

        Canvas { context, canvasSize in
            let scale = canvasSize.width / (size * 0.8)

            // Create gradient if gradient colors are provided
            let fillShading: GraphicsContext.Shading
            if let gradientColors = gradientColors, gradientColors.count > 1 {
                fillShading = GraphicsContext.Shading.linearGradient(
                    Gradient(colors: gradientColors),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height)
                )
            } else {
                fillShading = GraphicsContext.Shading.color(foregroundColor)
            }

            for row in 0..<moduleCount {
                for col in 0..<moduleCount {
                    guard qrMatrix[row][col] else { continue }

                    if logoImage != nil {
                        let distanceFromCenter = max(abs(row - center), abs(col - center))
                        if distanceFromCenter < logoRadius {
                            continue
                        }
                    }

                    let x = (offset + CGFloat(col) * moduleSize) * scale
                    let y = (offset + CGFloat(row) * moduleSize) * scale
                    let rect = CGRect(x: x, y: y, width: moduleSize * scale, height: moduleSize * scale)

                    let path = modulePath(for: rect)
                    context.fill(path, with: fillShading)
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
            Circle()
                .fill(.white)
                .frame(width: logoSize + 8, height: logoSize + 8)

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

        let size = Int(outputImage.extent.width)
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            qrMatrix = []
            return
        }

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
                matrix[row][col] = bytes[offset] == 0
            }
        }

        qrMatrix = matrix
    }
}

// MARK: - Static Generator
extension QRCodePreview {
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

        let scale = size / outputImage.extent.width
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

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
                QRCodePreview(content: "https://qreative.app")

                QRCodePreview(
                    content: "https://qreative.app",
                    foregroundColor: .accentPrimary,
                    isGlowing: true
                )

                QRCodePreview(
                    content: "Hello World",
                    size: 180,
                    foregroundColor: .accentTertiary,
                    shape: .dots
                )

                QRCodePreview(
                    content: "QReative",
                    size: 180,
                    foregroundColor: .accentSecondary,
                    shape: .rounded
                )

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
