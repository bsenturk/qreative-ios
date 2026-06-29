import SwiftUI
import AVFoundation

// MARK: - Scan Mode
/// The scanner's two modes. Drives both the viewfinder shape (square for QR,
/// wide rectangle for barcodes) and which code symbologies the camera reports.
enum ScanMode: String, CaseIterable, Identifiable {
    case qr
    case barcode

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .qr: return "QR"
        case .barcode: return "Barcode"
        }
    }

    /// Hint shown to first-time users, phrased per mode.
    var hint: LocalizedStringKey {
        switch self {
        case .qr: return "Point at a QR code to scan"
        case .barcode: return "Point at a barcode to scan"
        }
    }

    // MARK: - Viewfinder Frame
    /// QR uses a square; barcodes use a short, wide rectangle that matches the
    /// shape of a 1D barcode.
    var frameWidth: CGFloat {
        switch self {
        case .qr: return 260
        case .barcode: return 300
        }
    }

    var frameHeight: CGFloat {
        switch self {
        case .qr: return 260
        case .barcode: return 170
        }
    }

    // MARK: - Symbologies
    /// Code types the camera reports in this mode. QR mode covers 2D square
    /// codes; Barcode mode covers the common 1D linear symbologies (plus PDF417).
    var metadataTypes: [AVMetadataObject.ObjectType] {
        switch self {
        case .qr:
            return [.qr, .aztec, .dataMatrix]
        case .barcode:
            return [.ean8, .ean13, .upce, .code39, .code93, .code128, .codabar, .itf14, .pdf417]
        }
    }
}
