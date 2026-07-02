import SwiftUI

// MARK: - Privacy Policy View
// Shows the hosted privacy policy (GitHub Pages) so the App and the App Store
// listing always reference the same, single source of truth.
struct PrivacyPolicyView: View {
    var body: some View {
        LegalWebView(
            url: URL(string: "https://bsenturk.github.io/qreative-ios/privacy.html")!,
            title: "Privacy Policy"
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
