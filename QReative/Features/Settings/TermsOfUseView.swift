import SwiftUI

// MARK: - Terms of Use View
// Shows Apple's standard Licensed Application End User License Agreement (EULA),
// which Apple accepts as the Terms of Use for subscription apps.
struct TermsOfUseView: View {
    var body: some View {
        LegalWebView(
            url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
            title: "Terms of Use"
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        TermsOfUseView()
    }
}
