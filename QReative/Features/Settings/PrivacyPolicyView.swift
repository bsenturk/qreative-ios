import SwiftUI

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Policy for QReative")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Last updated: January 15, 2026")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .padding(.top, 20)

                // Introduction
                Text("This Privacy Policy explains how **QReative: QR Code Reader** (\"we,\" \"us,\" or \"our\") collects, uses, and discloses information about you when you use our mobile application (the \"App\").")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.9))

                Text("By using the App, you consent to the processing of your information as set forth in this Privacy Policy.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.9))

                // Section 1
                sectionView(
                    title: "1. Information We Collect",
                    content: []
                )

                subsectionView(
                    title: "A. Camera and Photo Library",
                    content: [
                        "Our App requires access to your device's camera and photo library to function effectively.",
                        "• **Camera:** To scan QR codes directly. **We do not send your camera feed to any server.** All scanning processing happens locally on your device.",
                        "• **Photo Library:** To save the QR codes you create or to scan QR codes from images stored in your gallery."
                    ]
                )

                subsectionView(
                    title: "B. Usage Data",
                    content: [
                        "We may collect anonymous usage data to improve our services. This includes device type, operating system version, and crash logs. This data is not linked to your personal identity."
                    ]
                )

                // Section 2
                sectionView(
                    title: "2. Third-Party Services",
                    content: [
                        "We use third-party services to facilitate our business, such as analytics, advertising, and payment processing. These services may collect information used to identify you.",
                        "",
                        "• **RevenueCat:** We use RevenueCat to manage our subscription infrastructure. RevenueCat may collect anonymous identifiers to validate your purchase status.",
                        "• **Google AdMob:** We use Google AdMob to display advertisements in the free version of the App. AdMob may collect data (such as advertising ID) to serve personalized ads.",
                        "  • **AdMob Privacy Policy:** https://policies.google.com/privacy"
                    ]
                )

                // Section 3
                sectionView(
                    title: "3. Data Storage",
                    content: [
                        "• **Scan History:** Your scan history is stored locally on your device. We do not have access to this data.",
                        "• **Created QR Codes:** QR codes you generate are processed on your device."
                    ]
                )

                // Section 4
                sectionView(
                    title: "4. Subscriptions and Payments",
                    content: [
                        "Payment processing for the \"QReative PRO\" subscription is handled directly by the Apple App Store. We do not process or store your credit card information."
                    ]
                )

                // Section 5
                sectionView(
                    title: "5. Security",
                    content: [
                        "We take reasonable measures to help protect information about you from loss, theft, misuse, and unauthorized access. However, no security system is impenetrable."
                    ]
                )

                // Section 6
                sectionView(
                    title: "6. Changes to This Policy",
                    content: [
                        "We may update this Privacy Policy from time to time. If we make changes, we will notify you by revising the date at the top of the policy."
                    ]
                )

                // Section 7
                sectionView(
                    title: "7. Contact Us",
                    content: [
                        "If you have any questions about this Privacy Policy, please contact us at:",
                        "**Email:** buraksenturktr@icloud.com"
                    ]
                )

                Spacer(minLength: 40)
            }
            .padding(.horizontal, Theme.spacing.screen)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Section View
    private func sectionView(title: String, content: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            ForEach(content, id: \.self) { text in
                if !text.isEmpty {
                    Text(parseMarkdown(text))
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
            }
        }
    }

    // MARK: - Subsection View
    private func subsectionView(title: String, content: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.95))

            ForEach(content, id: \.self) { text in
                if !text.isEmpty {
                    Text(parseMarkdown(text))
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
            }
        }
        .padding(.leading, 16)
    }

    // MARK: - Parse Markdown
    private func parseMarkdown(_ text: String) -> AttributedString {
        do {
            var attributedString = try AttributedString(markdown: text)
            return attributedString
        } catch {
            return AttributedString(text)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
