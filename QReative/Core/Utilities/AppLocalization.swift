import Foundation

/// App-wide localized string lookup for imperative (non-View) code.
///
/// In RELEASE this is identical to `String(localized:)` — it follows the user's
/// device language.
///
/// In DEBUG it resolves against the bundle chosen by the in-app language
/// switcher (Settings → DEBUG → Language) so every string — including ones
/// produced in models, view models and services — can be tested live.
///
/// Use this instead of `String(localized:)` everywhere a localized `String`
/// value is needed. SwiftUI `Text("literal")` does not need it (it already
/// follows `.environment(\.locale)`).
func appLocalized(_ key: String.LocalizationValue) -> String {
    #if DEBUG
    return String(localized: key, bundle: RuntimeLanguage.bundle)
    #else
    return String(localized: key)
    #endif
}
