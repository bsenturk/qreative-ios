import SwiftUI
import WebKit

// MARK: - Legal Web View
// Renders a hosted legal page (Apple EULA, Privacy Policy) in a WKWebView with a
// loading indicator. Shared by TermsOfUseView and PrivacyPolicyView.
struct LegalWebView: View {
    let url: URL
    let title: LocalizedStringKey
    @State private var isLoading = true

    var body: some View {
        WebView(url: url, isLoading: $isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                        .tint(Color.accentPrimary)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - WebView
private struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator { Coordinator(isLoading: $isLoading) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = UIColor(Color.backgroundPrimary)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let isLoading: Binding<Bool>
        init(isLoading: Binding<Bool>) { self.isLoading = isLoading }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading.wrappedValue = false
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading.wrappedValue = false
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading.wrappedValue = false
        }
    }
}
