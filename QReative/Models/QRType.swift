import SwiftUI

// MARK: - WiFi Security
enum WifiSecurity: String, CaseIterable, Identifiable {
    case wpa = "WPA"
    case wep = "WEP"
    case none = "nopass"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wpa: return "WPA/WPA2"
        case .wep: return "WEP"
        case .none: return "None"
        }
    }
}

// MARK: - QR Type
enum QRType: Identifiable, Equatable {
    case website(url: String)
    case wifi(ssid: String, password: String, security: WifiSecurity)
    case instagram(username: String)
    case text(content: String)
    case vcard(name: String, phone: String?, email: String?, company: String?)
    case email(address: String, subject: String?, body: String?)
    case phone(number: String)
    case sms(number: String, message: String?)

    // MARK: - Identifiable
    var id: String {
        switch self {
        case .website: return "website"
        case .wifi: return "wifi"
        case .instagram: return "instagram"
        case .text: return "text"
        case .vcard: return "vcard"
        case .email: return "email"
        case .phone: return "phone"
        case .sms: return "sms"
        }
    }

    // MARK: - Display Properties
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
        }
    }

    var subtitle: String {
        switch self {
        case .website: return "Link to any URL"
        case .wifi: return "Share WiFi credentials"
        case .instagram: return "Link to profile"
        case .text: return "Plain text message"
        case .vcard: return "Share contact info"
        case .email: return "Compose email"
        case .phone: return "Direct call"
        case .sms: return "Send text message"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .website:
            return [Color(hex: "6200EA"), Color(hex: "9C27B0")]
        case .wifi:
            return [Color(hex: "00B8D4"), Color(hex: "00E5FF")]
        case .instagram:
            return [Color(hex: "F58529"), Color(hex: "DD2A7B"), Color(hex: "8134AF")]
        case .text:
            return [Color(hex: "607D8B"), Color(hex: "455A64")]
        case .vcard:
            return [Color(hex: "4CAF50"), Color(hex: "2E7D32")]
        case .email:
            return [Color(hex: "FF5722"), Color(hex: "E64A19")]
        case .phone:
            return [Color(hex: "2196F3"), Color(hex: "1565C0")]
        case .sms:
            return [Color(hex: "9C27B0"), Color(hex: "7B1FA2")]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var placeholder: String {
        switch self {
        case .website: return "https://example.com"
        case .wifi: return "Network Name"
        case .instagram: return "username"
        case .text: return "Enter your text here..."
        case .vcard: return "John Doe"
        case .email: return "email@example.com"
        case .phone: return "+1 234 567 8900"
        case .sms: return "+1 234 567 8900"
        }
    }

    // MARK: - QR Content Generation
    func generateQRContent() -> String {
        switch self {
        case .website(let url):
            if url.lowercased().hasPrefix("http://") || url.lowercased().hasPrefix("https://") {
                return url
            }
            return "https://\(url)"

        case .wifi(let ssid, let password, let security):
            let securityType = security.rawValue
            if security == .none {
                return "WIFI:T:\(securityType);S:\(escapeWifiString(ssid));;"
            }
            return "WIFI:T:\(securityType);S:\(escapeWifiString(ssid));P:\(escapeWifiString(password));;"

        case .instagram(let username):
            let cleanUsername = username.replacingOccurrences(of: "@", with: "")
            return "https://instagram.com/\(cleanUsername)"

        case .text(let content):
            return content

        case .vcard(let name, let phone, let email, let company):
            var vcard = "BEGIN:VCARD\nVERSION:3.0\n"
            vcard += "FN:\(name)\n"
            if let phone = phone, !phone.isEmpty {
                vcard += "TEL:\(phone)\n"
            }
            if let email = email, !email.isEmpty {
                vcard += "EMAIL:\(email)\n"
            }
            if let company = company, !company.isEmpty {
                vcard += "ORG:\(company)\n"
            }
            vcard += "END:VCARD"
            return vcard

        case .email(let address, let subject, let body):
            var mailto = "mailto:\(address)"
            var params: [String] = []
            if let subject = subject, !subject.isEmpty {
                params.append("subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject)")
            }
            if let body = body, !body.isEmpty {
                params.append("body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body)")
            }
            if !params.isEmpty {
                mailto += "?\(params.joined(separator: "&"))"
            }
            return mailto

        case .phone(let number):
            let cleanNumber = number.replacingOccurrences(of: " ", with: "")
            return "tel:\(cleanNumber)"

        case .sms(let number, let message):
            let cleanNumber = number.replacingOccurrences(of: " ", with: "")
            if let message = message, !message.isEmpty {
                let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? message
                return "sms:\(cleanNumber)?body=\(encodedMessage)"
            }
            return "sms:\(cleanNumber)"
        }
    }

    // MARK: - Helpers
    private func escapeWifiString(_ string: String) -> String {
        var escaped = string
        escaped = escaped.replacingOccurrences(of: "\\", with: "\\\\")
        escaped = escaped.replacingOccurrences(of: ";", with: "\\;")
        escaped = escaped.replacingOccurrences(of: ",", with: "\\,")
        escaped = escaped.replacingOccurrences(of: ":", with: "\\:")
        escaped = escaped.replacingOccurrences(of: "\"", with: "\\\"")
        return escaped
    }

    // MARK: - Factory
    static func fromId(_ id: String) -> QRType? {
        switch id {
        case "website": return .website(url: "")
        case "wifi": return .wifi(ssid: "", password: "", security: .wpa)
        case "instagram": return .instagram(username: "")
        case "text": return .text(content: "")
        case "vcard": return .vcard(name: "", phone: nil, email: nil, company: nil)
        case "email": return .email(address: "", subject: nil, body: nil)
        case "phone": return .phone(number: "")
        case "sms": return .sms(number: "", message: nil)
        default: return nil
        }
    }

    // MARK: - Validation
    var isValid: Bool {
        switch self {
        case .website(let url):
            return !url.isEmpty
        case .wifi(let ssid, let password, let security):
            return !ssid.isEmpty && (security == .none || !password.isEmpty)
        case .instagram(let username):
            return !username.isEmpty
        case .text(let content):
            return !content.isEmpty
        case .vcard(let name, _, _, _):
            return !name.isEmpty
        case .email(let address, _, _):
            return !address.isEmpty && address.contains("@")
        case .phone(let number):
            return !number.isEmpty && number.count >= 7
        case .sms(let number, _):
            return !number.isEmpty && number.count >= 7
        }
    }
}

// MARK: - QR Type Template (for selection grid)
struct QRTypeTemplate: Identifiable {
    let id: String
    let type: QRType
    let isPremium: Bool

    var icon: String { type.icon }
    var title: String { type.title }
    var subtitle: String { type.subtitle }
    var gradientColors: [Color] { type.gradientColors }
    var gradient: LinearGradient { type.gradient }
}

extension QRTypeTemplate {
    static let allTemplates: [QRTypeTemplate] = [
        QRTypeTemplate(id: "website", type: .website(url: ""), isPremium: false),
        QRTypeTemplate(id: "wifi", type: .wifi(ssid: "", password: "", security: .wpa), isPremium: false),
        QRTypeTemplate(id: "instagram", type: .instagram(username: ""), isPremium: false),
        QRTypeTemplate(id: "text", type: .text(content: ""), isPremium: false),
        QRTypeTemplate(id: "vcard", type: .vcard(name: "", phone: nil, email: nil, company: nil), isPremium: true),
        QRTypeTemplate(id: "email", type: .email(address: "", subject: nil, body: nil), isPremium: false),
        QRTypeTemplate(id: "phone", type: .phone(number: ""), isPremium: false),
        QRTypeTemplate(id: "sms", type: .sms(number: "", message: nil), isPremium: true),
    ]

    static let freeTemplates: [QRTypeTemplate] = allTemplates.filter { !$0.isPremium }
    static let premiumTemplates: [QRTypeTemplate] = allTemplates.filter { $0.isPremium }
}
