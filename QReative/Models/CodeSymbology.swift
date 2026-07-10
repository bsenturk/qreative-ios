import SwiftUI
import AVFoundation

// MARK: - Code Symbology
/// The actual encoding of a scanned code (QR vs the various barcode types).
/// Stored on `HistoryItem` so the app can re-render and label a scanned code as
/// what it really was instead of always treating it as a QR code.
enum CodeSymbology: String, Codable {
    case qr
    case ean13
    case ean8
    case upca
    case upce
    case code39
    case code93
    case code128
    case codabar
    case itf14
    case pdf417
    case aztec
    case dataMatrix

    init(metadataType: AVMetadataObject.ObjectType) {
        switch metadataType {
        case .qr: self = .qr
        case .ean13: self = .ean13
        case .ean8: self = .ean8
        case .upce: self = .upce
        case .code39: self = .code39
        case .code93: self = .code93
        case .code128: self = .code128
        case .codabar: self = .codabar
        case .itf14: self = .itf14
        case .pdf417: self = .pdf417
        case .aztec: self = .aztec
        case .dataMatrix: self = .dataMatrix
        default: self = .qr
        }
    }

    /// Resolves the true symbology from the metadata type and decoded value.
    /// AVFoundation reports UPC-A codes as a 13-digit EAN-13 with a leading `0`
    /// (GS1 prefix 0 is the UPC-A range), so detect that case here.
    static func detect(metadataType: AVMetadataObject.ObjectType, value: String) -> CodeSymbology {
        let base = CodeSymbology(metadataType: metadataType)
        if base == .ean13, value.count == 13, value.hasPrefix("0"),
           value.allSatisfy(\.isNumber) {
            return .upca
        }
        return base
    }

    /// True for 1D linear barcodes — these render as a wide rectangle.
    var isBarcode: Bool {
        switch self {
        case .ean13, .ean8, .upca, .upce, .code39, .code93, .code128, .codabar, .itf14:
            return true
        case .qr, .pdf417, .aztec, .dataMatrix:
            return false
        }
    }

    /// Human-friendly name shown in the history row and detail header.
    var displayName: String {
        switch self {
        case .qr: return "QR Code"
        case .ean13: return "EAN-13"
        case .ean8: return "EAN-8"
        case .upca: return "UPC-A"
        case .upce: return "UPC-E"
        case .code39: return "Code 39"
        case .code93: return "Code 93"
        case .code128: return "Code 128"
        case .codabar: return "Codabar"
        case .itf14: return "ITF-14"
        case .pdf417: return "PDF417"
        case .aztec: return "Aztec"
        case .dataMatrix: return "Data Matrix"
        }
    }

    /// SF Symbol used when representing this symbology as an icon.
    var icon: String {
        isBarcode ? "barcode" : "qrcode"
    }
}

// MARK: - Detected Code
/// A live camera detection: the decoded value plus the symbology it came from.
struct DetectedCode: Equatable {
    let value: String
    let symbology: CodeSymbology
}
