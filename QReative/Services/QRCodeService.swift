import UIKit
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

// MARK: - QR Code Service Error
enum QRCodeServiceError: LocalizedError {
    case generationFailed
    case invalidContent
    case photoLibraryAccessDenied
    case saveFailed(Error)
    case noQRCodeFound

    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return "Failed to generate QR code"
        case .invalidContent:
            return "Invalid QR code content"
        case .photoLibraryAccessDenied:
            return "Photo library access denied"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .noQRCodeFound:
            return "No QR code found in image"
        }
    }
}

// MARK: - QR Code Service
final class QRCodeService {

    // MARK: - Singleton
    static let shared = QRCodeService()

    // MARK: - Private Properties
    private let context = CIContext()

    // MARK: - Init
    private init() {}

    // MARK: - Generate Basic QR Code
    func generateQRCode(from string: String, size: CGSize = CGSize(width: 512, height: 512)) -> UIImage? {
        guard !string.isEmpty else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let scaleX = size.width / outputImage.extent.width
        let scaleY = size.height / outputImage.extent.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Generate Styled QR Code
    func generateStyledQRCode(
        content: String,
        size: CGSize = CGSize(width: 512, height: 512),
        foregroundColor: UIColor = .black,
        backgroundColor: UIColor = .white,
        shape: QRShape = .squares,
        logo: UIImage? = nil
    ) -> UIImage? {
        guard !content.isEmpty else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(content.utf8)
        filter.correctionLevel = logo != nil ? "H" : "M"

        guard let outputImage = filter.outputImage else { return nil }

        let qrSize = Int(outputImage.extent.width)
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent),
              let matrix = extractMatrix(from: cgImage, size: qrSize) else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        let styledImage = renderer.image { ctx in
            let context = ctx.cgContext

            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRect(origin: .zero, size: size))

            let moduleSize = size.width / CGFloat(qrSize)
            let inset = moduleSize * 0.1

            context.setFillColor(foregroundColor.cgColor)

            for row in 0..<qrSize {
                for col in 0..<qrSize {
                    guard matrix[row][col] else { continue }

                    if logo != nil {
                        let logoRadius = Int(Double(qrSize) * 0.2)
                        let center = qrSize / 2
                        let distanceFromCenter = max(abs(row - center), abs(col - center))
                        if distanceFromCenter < logoRadius {
                            continue
                        }
                    }

                    let x = CGFloat(col) * moduleSize
                    let y = CGFloat(row) * moduleSize
                    let rect = CGRect(x: x + inset, y: y + inset, width: moduleSize - inset * 2, height: moduleSize - inset * 2)

                    drawModule(in: context, rect: rect, shape: shape, moduleSize: moduleSize)
                }
            }

            if let logo = logo {
                drawLogo(logo, in: context, canvasSize: size)
            }
        }

        return styledImage
    }

    // MARK: - Generate with Gradient
    func generateGradientQRCode(
        content: String,
        size: CGSize = CGSize(width: 512, height: 512),
        gradientColors: [UIColor],
        backgroundColor: UIColor = .white,
        shape: QRShape = .squares,
        logo: UIImage? = nil
    ) -> UIImage? {
        guard !content.isEmpty, gradientColors.count >= 2 else { return nil }

        guard let blackQR = generateStyledQRCode(
            content: content,
            size: size,
            foregroundColor: .black,
            backgroundColor: .clear,
            shape: shape,
            logo: nil
        ) else { return nil }

        let renderer = UIGraphicsImageRenderer(size: size)
        let gradientImage = renderer.image { ctx in
            let context = ctx.cgContext

            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRect(origin: .zero, size: size))

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = gradientColors.map { $0.cgColor } as CFArray
            let locations: [CGFloat] = gradientColors.enumerated().map { CGFloat($0.offset) / CGFloat(gradientColors.count - 1) }

            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return }

            let startPoint = CGPoint.zero
            let endPoint = CGPoint(x: size.width, y: size.height)
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])

            guard let qrCGImage = blackQR.cgImage else { return }
            context.clip(to: CGRect(origin: .zero, size: size), mask: qrCGImage)
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        }

        if let logo = logo {
            return addLogo(logo, to: gradientImage, size: size)
        }

        return gradientImage
    }

    // MARK: - Read QR Code
    func readQRCode(from image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: context,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )

        guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature],
              let qrFeature = features.first else {
            return nil
        }

        return qrFeature.messageString
    }

    func readAllQRCodes(from image: UIImage) -> [String] {
        guard let ciImage = CIImage(image: image) else { return [] }

        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: context,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )

        guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature] else {
            return []
        }

        return features.compactMap { $0.messageString }
    }

    // MARK: - Save to Photos
    func saveToPhotos(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        guard status == .authorized || status == .limited else {
            throw QRCodeServiceError.photoLibraryAccessDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else if let error = error {
                    continuation.resume(throwing: QRCodeServiceError.saveFailed(error))
                } else {
                    continuation.resume(throwing: QRCodeServiceError.saveFailed(NSError(domain: "QRCodeService", code: -1)))
                }
            }
        }
    }

    // MARK: - Private Helpers
    private func extractMatrix(from cgImage: CGImage, size: Int) -> [[Bool]]? {
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return nil
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

        return matrix
    }

    private func drawModule(in context: CGContext, rect: CGRect, shape: QRShape, moduleSize: CGFloat) {
        switch shape {
        case .squares:
            context.fill(rect)

        case .dots:
            let diameter = min(rect.width, rect.height)
            let circleRect = CGRect(
                x: rect.midX - diameter / 2,
                y: rect.midY - diameter / 2,
                width: diameter,
                height: diameter
            )
            context.fillEllipse(in: circleRect)

        case .rounded:
            let cornerRadius = rect.width * 0.3
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            context.addPath(path.cgPath)
            context.fillPath()
        }
    }

    private func drawLogo(_ logo: UIImage, in context: CGContext, canvasSize: CGSize) {
        let logoSize = canvasSize.width * 0.22
        let logoRect = CGRect(
            x: (canvasSize.width - logoSize) / 2,
            y: (canvasSize.height - logoSize) / 2,
            width: logoSize,
            height: logoSize
        )

        let backgroundSize = logoSize + 8
        let backgroundRect = CGRect(
            x: (canvasSize.width - backgroundSize) / 2,
            y: (canvasSize.height - backgroundSize) / 2,
            width: backgroundSize,
            height: backgroundSize
        )
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: backgroundRect)

        if let cgImage = logo.cgImage {
            context.saveGState()
            context.addEllipse(in: logoRect)
            context.clip()
            context.draw(cgImage, in: logoRect)
            context.restoreGState()
        }
    }

    private func addLogo(_ logo: UIImage, to image: UIImage, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            image.draw(in: CGRect(origin: .zero, size: size))
            drawLogo(logo, in: ctx.cgContext, canvasSize: size)
        }
    }

    // MARK: - Get PNG Data
    func getPNGData(from image: UIImage) -> Data? {
        image.pngData()
    }

    func getJPEGData(from image: UIImage, quality: CGFloat = 0.9) -> Data? {
        image.jpegData(compressionQuality: quality)
    }
}

// MARK: - Convenience Extensions
extension QRCodeService {

    func quickGenerate(content: String, style: QuickStyle = .default) -> UIImage? {
        switch style {
        case .default:
            return generateQRCode(from: content)

        case .purple:
            return generateStyledQRCode(
                content: content,
                foregroundColor: UIColor(Color.accentPrimary),
                backgroundColor: .white,
                shape: .squares
            )

        case .rounded:
            return generateStyledQRCode(
                content: content,
                foregroundColor: .black,
                backgroundColor: .white,
                shape: .rounded
            )

        case .dots:
            return generateStyledQRCode(
                content: content,
                foregroundColor: .black,
                backgroundColor: .white,
                shape: .dots
            )
        }
    }

    enum QuickStyle {
        case `default`
        case purple
        case rounded
        case dots
    }
}
