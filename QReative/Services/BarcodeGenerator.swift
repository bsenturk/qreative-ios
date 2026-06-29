import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Barcode Generator
/// Renders a displayable image for non-QR symbologies (linear barcodes, PDF417,
/// Aztec). QR and Data Matrix return `nil` — those are rendered through the
/// existing `QRCodePreview` path instead.
///
/// Core Image only ships generators for Code 128, PDF417 and Aztec, so every 1D
/// linear type is drawn as a Code 128 of the same digits: it stays a scannable
/// horizontal barcode that encodes the original value, which is what matters for
/// re-displaying a scanned code in history.
enum BarcodeGenerator {

    private static let context = CIContext()

    /// Whether this symbology is rendered as a wide (1D / PDF417) image rather
    /// than a square one (Aztec).
    static func isWide(_ symbology: CodeSymbology) -> Bool {
        symbology != .aztec
    }

    /// Returns a high-resolution barcode image, or `nil` for QR / Data Matrix
    /// (handled elsewhere) and for content that can't be encoded.
    static func image(
        for content: String,
        symbology: CodeSymbology,
        foreground: UIColor = .black,
        background: UIColor = .white
    ) -> UIImage? {
        let filterName: String
        switch symbology {
        case .pdf417:
            filterName = "CIPDF417BarcodeGenerator"
        case .aztec:
            filterName = "CIAztecCodeGenerator"
        case .ean13, .ean8, .upca, .upce, .code39, .code93, .code128, .codabar, .itf14:
            filterName = "CICode128BarcodeGenerator"
        case .qr, .dataMatrix:
            return nil
        }

        // Code 128 needs Latin-1/ASCII; Aztec/PDF417 accept UTF-8.
        let encoding: String.Encoding = (filterName == "CICode128BarcodeGenerator") ? .ascii : .utf8
        guard let data = content.data(using: encoding) ?? content.data(using: .utf8),
              let filter = CIFilter(name: filterName) else {
            return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        if filterName == "CICode128BarcodeGenerator" {
            filter.setValue(8, forKey: "inputQuietSpace")
        }

        guard let output = filter.outputImage, !output.extent.isEmpty else { return nil }

        // Scale up to a crisp render. 1D codes are stretched vertically (the
        // height carries no data); 2D codes keep their aspect ratio.
        let targetWidth: CGFloat = 600
        let scaleX = targetWidth / output.extent.width
        let scaleY = isWide(symbology)
            ? (200 / output.extent.height)
            : scaleX
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Apply foreground/background colors.
        let colored = scaled.applyingFilter("CIFalseColor", parameters: [
            "inputColor0": CIColor(color: foreground),
            "inputColor1": CIColor(color: background)
        ])

        guard let cgImage = context.createCGImage(colored, from: colored.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
