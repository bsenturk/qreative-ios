import Foundation

#if DEBUG

// MARK: - Runtime Language Override (DEBUG only)
//
// Holds the `.lproj` bundle for the language picked at runtime (Settings →
// DEBUG → Language). `appLocalized(_:)` resolves imperative strings against
// this bundle, while SwiftUI `Text("...")` literals follow `.environment(\.locale)`.
// Together they let every localized string be tested live without changing the
// device language.
//
// Compiled only in DEBUG builds, so it can never ship.

enum RuntimeLanguage {
    /// The bundle imperative localized strings are resolved against.
    /// `nonisolated(unsafe)` is acceptable here: it is mutated only from the
    /// main actor (`LanguageManager`) and this whole type is DEBUG-only.
    nonisolated(unsafe) static var bundle: Bundle = .main

    /// Points `bundle` at the given `.lproj` resource (e.g. `"tr"`, `"pt-BR"`),
    /// or back to `.main` (system language) when `code` is `nil`.
    static func set(_ code: String?) {
        if let code,
           let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let languageBundle = Bundle(path: path) {
            bundle = languageBundle
        } else {
            bundle = .main
        }
    }
}

#endif
