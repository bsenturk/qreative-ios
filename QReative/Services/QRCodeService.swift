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

            // Fill background
            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRect(origin: .zero, size: size))

            // Calculate module size with quiet zone (at least 4 modules padding)
            let quietZoneModules: CGFloat = 4
            let totalModules = CGFloat(qrSize) + (quietZoneModules * 2)
            let moduleSize = size.width / totalModules
            let qrOffset = quietZoneModules * moduleSize
            // Use smaller inset for dots to improve scanability
            let inset = getInset(for: shape, moduleSize: moduleSize)

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

                    let x = qrOffset + CGFloat(col) * moduleSize
                    let y = qrOffset + CGFloat(row) * moduleSize
                    let rect = CGRect(x: x + inset, y: y + inset, width: moduleSize - inset * 2, height: moduleSize - inset * 2)

                    drawModule(in: context, rect: rect, shape: shape, moduleSize: moduleSize)
                }
            }

            if let logo = logo {
                drawLogo(logo, in: context, canvasSize: size, qrSize: qrSize, moduleSize: moduleSize, offset: qrOffset)
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
        let gradientImage = renderer.image { ctx in
            let context = ctx.cgContext

            // Draw background
            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRect(origin: .zero, size: size))

            // Calculate module size with quiet zone (at least 4 modules padding)
            let quietZoneModules: CGFloat = 4
            let totalModules = CGFloat(qrSize) + (quietZoneModules * 2)
            let moduleSize = size.width / totalModules
            let qrOffset = quietZoneModules * moduleSize
            // Use smaller inset for dots to improve scanability
            let inset = getInset(for: shape, moduleSize: moduleSize)

            // Create gradient
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = gradientColors.map { $0.cgColor } as CFArray
            let locations: [CGFloat] = gradientColors.enumerated().map { CGFloat($0.offset) / CGFloat(gradientColors.count - 1) }

            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return }

            let startPoint = CGPoint.zero
            let endPoint = CGPoint(x: size.width, y: size.height)

            // Draw gradient modules
            context.saveGState()

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

                    let x = qrOffset + CGFloat(col) * moduleSize
                    let y = qrOffset + CGFloat(row) * moduleSize
                    let rect = CGRect(x: x + inset, y: y + inset, width: moduleSize - inset * 2, height: moduleSize - inset * 2)

                    context.saveGState()
                    addPathForShape(shape, in: context, rect: rect, moduleSize: moduleSize)
                    context.clip()
                    context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
                    context.restoreGState()
                }
            }

            context.restoreGState()

            // Draw logo
            if let logo = logo {
                drawLogo(logo, in: context, canvasSize: size, qrSize: qrSize, moduleSize: moduleSize, offset: qrOffset)
            }
        }

        return gradientImage
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
    private func getInset(for shape: QRShape, moduleSize: CGFloat) -> CGFloat {
        switch shape {
        case .squares:
            // Use minimal inset for squares to ensure scanability
            return moduleSize * 0.03
        case .rounded:
            // Use minimal inset for rounded to ensure scanability
            return moduleSize * 0.03
        case .dots:
            // Use minimal inset for dots to ensure scanability
            return moduleSize * 0.02
        }
    }

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
        let length = CFDataGetLength(data)

        for row in 0..<size {
            for col in 0..<size {
                let offset = row * bytesPerRow + col * bytesPerPixel
                // Guard against an unexpected pixel layout (stride/format change
                // across iOS versions) so we degrade gracefully instead of
                // reading out of bounds.
                guard offset >= 0, offset < length else { return nil }
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

    private func addPathForShape(_ shape: QRShape, in context: CGContext, rect: CGRect, moduleSize: CGFloat) {
        switch shape {
        case .squares:
            context.addRect(rect)

        case .dots:
            let diameter = min(rect.width, rect.height)
            let circleRect = CGRect(
                x: rect.midX - diameter / 2,
                y: rect.midY - diameter / 2,
                width: diameter,
                height: diameter
            )
            context.addEllipse(in: circleRect)

        case .rounded:
            let cornerRadius = rect.width * 0.3
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            context.addPath(path.cgPath)
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

        // Use UIImage.draw so the overlay (logo/emoji) keeps the correct
        // orientation; CGContext.draw(_:in:) would render it upside-down in a
        // UIKit (top-left origin) renderer context.
        context.saveGState()
        context.addEllipse(in: logoRect)
        context.clip()
        logo.draw(in: logoRect)
        context.restoreGState()
    }

    private func drawLogo(_ logo: UIImage, in context: CGContext, canvasSize: CGSize, qrSize: Int, moduleSize: CGFloat, offset: CGFloat) {
        // Calculate logo size based on QR code area (not canvas)
        let qrCodeSize = CGFloat(qrSize) * moduleSize
        let logoSize = qrCodeSize * 0.22

        // Center logo in QR code area
        let qrCodeCenterX = offset + (qrCodeSize / 2)
        let qrCodeCenterY = offset + (qrCodeSize / 2)

        let logoRect = CGRect(
            x: qrCodeCenterX - logoSize / 2,
            y: qrCodeCenterY - logoSize / 2,
            width: logoSize,
            height: logoSize
        )

        let backgroundSize = logoSize + 8
        let backgroundRect = CGRect(
            x: qrCodeCenterX - backgroundSize / 2,
            y: qrCodeCenterY - backgroundSize / 2,
            width: backgroundSize,
            height: backgroundSize
        )
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: backgroundRect)

        // Use UIImage.draw so the overlay keeps the correct orientation (see note above).
        context.saveGState()
        context.addEllipse(in: logoRect)
        context.clip()
        logo.draw(in: logoRect)
        context.restoreGState()
    }

    private func addLogo(_ logo: UIImage, to image: UIImage, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            image.draw(in: CGRect(origin: .zero, size: size))
            drawLogo(logo, in: ctx.cgContext, canvasSize: size)
        }
    }

}
