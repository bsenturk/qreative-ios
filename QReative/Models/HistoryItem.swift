import SwiftUI

// MARK: - History Item Type (Codable version of QRType)
enum HistoryItemType: String, Codable, CaseIterable {
    case website
    case wifi
    case instagram
    case text
    case vcard
    case email
    case phone
    case sms
    case unknown

    var icon: String {
        switch self {
        case .website: return "globe"
        case .wifi: return "wifi"
        case .instagram: return "camera.circle.fill"
        case .text: return "doc.text.fill"
        case .vcard: return "person.crop.rectangle.fill"
        case .email: return "envelope.fill"
        case .phone: return "phone.fill"
        case .sms: return "message.fill"
        case .unknown: return "qrcode"
        }
    }

    var title: String {
        switch self {
        case .website: return "Website"
        case .wifi: return "WiFi"
        case .instagram: return "Instagram"
        case .text: return "Text"
        case .vcard: return "Contact"
        case .email: return "Email"
        case .phone: return "Phone"
        case .sms: return "SMS"
        case .unknown: return "QR Code"
        }
    }

    var accentColor: Color {
        switch self {
        case .website: return Color(hex: "6200EA")
        case .wifi: return Color(hex: "00E5FF")
        case .instagram: return Color(hex: "E1306C")
        case .text: return Color(hex: "607D8B")
        case .vcard: return Color(hex: "4CAF50")
        case .email: return Color(hex: "FF5722")
        case .phone: return Color(hex: "2196F3")
        case .sms: return Color(hex: "9C27B0")
        case .unknown: return Color(hex: "6200EA")
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .website: return [Color(hex: "6200EA"), Color(hex: "9C27B0")]
        case .wifi: return [Color(hex: "00B8D4"), Color(hex: "00E5FF")]
        case .instagram: return [Color(hex: "F58529"), Color(hex: "DD2A7B")]
        case .text: return [Color(hex: "607D8B"), Color(hex: "455A64")]
        case .vcard: return [Color(hex: "4CAF50"), Color(hex: "2E7D32")]
        case .email: return [Color(hex: "FF5722"), Color(hex: "E64A19")]
        case .phone: return [Color(hex: "2196F3"), Color(hex: "1565C0")]
        case .sms: return [Color(hex: "9C27B0"), Color(hex: "7B1FA2")]
        case .unknown: return [Color(hex: "6200EA"), Color(hex: "9C27B0")]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Detection
    static func detect(from content: String) -> HistoryItemType {
        let lowercased = content.lowercased()

        if lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://") {
            if lowercased.contains("instagram.com") {
                return .instagram
            }
            return .website
        } else if lowercased.hasPrefix("wifi:") {
            return .wifi
        } else if lowercased.hasPrefix("mailto:") || (content.contains("@") && content.contains(".")) {
            return .email
        } else if lowercased.hasPrefix("tel:") {
            return .phone
        } else if lowercased.hasPrefix("sms:") || lowercased.hasPrefix("smsto:") {
            return .sms
        } else if lowercased.hasPrefix("begin:vcard") {
            return .vcard
        }

        return .text
    }
}

// MARK: - History Item
struct HistoryItem: Identifiable, Codable, Equatable {

    // MARK: - Properties
    let id: UUID
    let content: String
    let type: HistoryItemType
    let createdAt: Date
    var thumbnailData: Data?
    var customColor: String?
    var customShape: String?
    var hasLogo: Bool

    // MARK: - Init
    init(
        id: UUID = UUID(),
        content: String,
        type: HistoryItemType? = nil,
        createdAt: Date = Date(),
        thumbnailData: Data? = nil,
        customColor: String? = nil,
        customShape: String? = nil,
        hasLogo: Bool = false
    ) {
        self.id = id
        self.content = content
        self.type = type ?? HistoryItemType.detect(from: content)
        self.createdAt = createdAt
        self.thumbnailData = thumbnailData
        self.customColor = customColor
        self.customShape = customShape
        self.hasLogo = hasLogo
    }

    // MARK: - Computed Properties
    var displayTitle: String {
        switch type {
        case .website:
            return formatURL(content)
        case .wifi:
            return extractWiFiSSID(content) ?? "WiFi Network"
        case .instagram:
            return extractInstagramUsername(content) ?? "Instagram"
        case .vcard:
            return extractVCardName(content) ?? "Contact"
        case .email:
            return extractEmail(content) ?? "Email"
        case .phone:
            return formatPhoneNumber(content)
        case .sms:
            return formatPhoneNumber(content.replacingOccurrences(of: "sms:", with: ""))
        case .text:
            return content.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines)
                + (content.count > 50 ? "..." : "")
        case .unknown:
            return "QR Code"
        }
    }

    var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(createdAt) {
            return "Today, \(timeFormatter.string(from: createdAt))"
        } else if calendar.isDateInYesterday(createdAt) {
            return "Yesterday, \(timeFormatter.string(from: createdAt))"
        } else if calendar.isDate(createdAt, equalTo: now, toGranularity: .weekOfYear) {
            return "\(dayFormatter.string(from: createdAt)), \(timeFormatter.string(from: createdAt))"
        } else if calendar.isDate(createdAt, equalTo: now, toGranularity: .year) {
            return dateFormatter.string(from: createdAt)
        } else {
            return fullDateFormatter.string(from: createdAt)
        }
    }

    var shortFormattedDate: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(createdAt) {
            return timeFormatter.string(from: createdAt)
        } else if calendar.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else {
            return shortDateFormatter.string(from: createdAt)
        }
    }

    var typeIcon: String {
        type.icon
    }

    var accentColor: Color {
        type.accentColor
    }

    var gradient: LinearGradient {
        type.gradient
    }

    var thumbnailImage: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Private Formatters
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }

    private var fullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }

    // MARK: - Content Extraction Helpers
    private func formatURL(_ url: String) -> String {
        var formatted = url
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")

        if formatted.hasSuffix("/") {
            formatted = String(formatted.dropLast())
        }

        if formatted.count > 40 {
            formatted = String(formatted.prefix(37)) + "..."
        }

        return formatted
    }

    private func extractWiFiSSID(_ content: String) -> String? {
        guard let ssidRange = content.range(of: "S:"),
              let endRange = content.range(of: ";", range: ssidRange.upperBound..<content.endIndex) else {
            return nil
        }
        return String(content[ssidRange.upperBound..<endRange.lowerBound])
            .replacingOccurrences(of: "\\;", with: ";")
    }

    private func extractInstagramUsername(_ url: String) -> String? {
        guard url.contains("instagram.com") else { return nil }

        let components = url
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
            .replacingOccurrences(of: "instagram.com/", with: "")
            .components(separatedBy: "/")

        return components.first.map { "@\($0)" }
    }

    private func extractVCardName(_ content: String) -> String? {
        let lines = content.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("FN:") {
                return String(line.dropFirst(3))
            }
        }
        return nil
    }

    private func extractEmail(_ content: String) -> String? {
        let cleaned = content
            .replacingOccurrences(of: "mailto:", with: "")
            .components(separatedBy: "?")
            .first

        return cleaned
    }

    private func formatPhoneNumber(_ number: String) -> String {
        return number
            .replacingOccurrences(of: "tel:", with: "")
            .replacingOccurrences(of: "sms:", with: "")
    }
}

// MARK: - Sample Data
extension HistoryItem {
    static let samples: [HistoryItem] = [
        HistoryItem(
            content: "https://www.apple.com",
            createdAt: Date()
        ),
        HistoryItem(
            content: "WIFI:T:WPA;S:HomeNetwork;P:password123;;",
            createdAt: Date().addingTimeInterval(-3600)
        ),
        HistoryItem(
            content: "https://instagram.com/apple",
            createdAt: Date().addingTimeInterval(-86400)
        ),
        HistoryItem(
            content: "BEGIN:VCARD\nVERSION:3.0\nFN:John Doe\nTEL:+1234567890\nEND:VCARD",
            createdAt: Date().addingTimeInterval(-172800)
        ),
        HistoryItem(
            content: "Hello, this is a sample text QR code content.",
            createdAt: Date().addingTimeInterval(-604800)
        ),
    ]
}
