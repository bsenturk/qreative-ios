import SwiftUI
import Combine

#if DEBUG

// MARK: - App Language (DEBUG only)
/// The languages QReative ships in. `code` matches the `.lproj` resource name
/// in the built app (also used as the `Locale` identifier).
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english   = "en"
    case turkish   = "tr"
    case arabic    = "ar"
    case german    = "de"
    case spanish   = "es"
    case french    = "fr"
    case indonesian = "id"
    case japanese  = "ja"
    case portugueseBR = "pt-BR"
    case thai      = "th"
    case vietnamese = "vi"

    var id: String { rawValue }

    /// `.lproj` resource name + `Locale` identifier, or `nil` for system default.
    var localeCode: String? {
        self == .system ? nil : rawValue
    }

    /// Native display name shown in the picker.
    var displayName: String {
        switch self {
        case .system:       return String(localized: "System Default")
        case .english:      return "English"
        case .turkish:      return "Türkçe"
        case .arabic:       return "العربية"
        case .german:       return "Deutsch"
        case .spanish:      return "Español"
        case .french:       return "Français"
        case .indonesian:   return "Bahasa Indonesia"
        case .japanese:     return "日本語"
        case .portugueseBR: return "Português (Brasil)"
        case .thai:         return "ไทย"
        case .vietnamese:   return "Tiếng Việt"
        }
    }

    var flag: String {
        switch self {
        case .system:       return "🌐"
        case .english:      return "🇬🇧"
        case .turkish:      return "🇹🇷"
        case .arabic:       return "🇸🇦"
        case .german:       return "🇩🇪"
        case .spanish:      return "🇪🇸"
        case .french:       return "🇫🇷"
        case .indonesian:   return "🇮🇩"
        case .japanese:     return "🇯🇵"
        case .portugueseBR: return "🇧🇷"
        case .thai:         return "🇹🇭"
        case .vietnamese:   return "🇻🇳"
        }
    }
}

// MARK: - Language Manager (DEBUG only)
/// Holds the runtime-selected language and applies it to `Bundle.main` so every
/// localized string updates live. Publishing `current` drives a full SwiftUI
/// rebuild from the root (see `QReativeApp`).
@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    private let storageKey = "debug_app_language"

    @Published var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: storageKey)
            RuntimeLanguage.set(current.localeCode)
        }
    }

    /// Locale to inject into the SwiftUI environment so `Text("...")` resolves
    /// against the selected language.
    var locale: Locale {
        Locale(identifier: current.localeCode ?? Locale.current.identifier)
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: storageKey)
        let language = AppLanguage.allCases.first { $0.rawValue == saved } ?? .system
        current = language
        RuntimeLanguage.set(language.localeCode)
    }
}

#endif
