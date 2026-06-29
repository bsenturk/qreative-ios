import SwiftUI
import Combine

// MARK: - App Settings
/// User-tunable preferences, persisted in `UserDefaults` and shared app-wide.
/// `HapticManager` reads the haptic key directly (so it stays decoupled and
/// callable from any context); everything else observes this object.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // UserDefaults keys (also read directly by HapticManager).
    enum Keys {
        static let hapticFeedback = "settings.hapticFeedback"
        static let autoOpenLinks = "settings.autoOpenLinks"
        static let scanSound = "settings.scanSound"
    }

    @Published var hapticFeedbackEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticFeedbackEnabled, forKey: Keys.hapticFeedback) }
    }

    @Published var autoOpenLinks: Bool {
        didSet { UserDefaults.standard.set(autoOpenLinks, forKey: Keys.autoOpenLinks) }
    }

    @Published var scanSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(scanSoundEnabled, forKey: Keys.scanSound) }
    }

    private init() {
        let defaults = UserDefaults.standard
        // Sensible defaults: haptics on, sound on, auto-open off (safer).
        hapticFeedbackEnabled = defaults.object(forKey: Keys.hapticFeedback) as? Bool ?? true
        autoOpenLinks = defaults.object(forKey: Keys.autoOpenLinks) as? Bool ?? false
        scanSoundEnabled = defaults.object(forKey: Keys.scanSound) as? Bool ?? true
    }
}
