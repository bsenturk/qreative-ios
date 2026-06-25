import SwiftUI

// MARK: - Terms of Use View
struct TermsOfUseView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Terms of Use (EULA)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text("Last updated: January 15, 2026")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.ink2)
                }
                .padding(.top, 20)

                // Introduction
                Text("By downloading or using the app **QReative: QR Code Reader**, these terms will automatically apply to you.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)

                // Section 1
                sectionView(
                    title: "1. Use of the App",
                    content: [
                        "You agree to use the App only for lawful purposes. You are strictly prohibited from using the App to generate QR codes that link to illegal, malicious, or harmful content (e.g., phishing sites, viruses)."
                    ]
                )

                // Section 2
                sectionView(
                    title: "2. Intellectual Property",
                    content: [
                        "The App, including its original content, design, and functionality, is owned by **Burak Şentürk** and is protected by international copyright laws."
                    ]
                )

                // Section 3
                sectionView(
                    title: "3. Subscriptions (QReative PRO)",
                    content: [
                        "The App offers a premium subscription service (\"QReative PRO\") that grants access to advanced features such as custom colors, logo integration, and unlimited history.",
                        "",
                        "• **Payment:** Payment will be charged to your iTunes Account at confirmation of purchase.",
                        "• **Auto-Renewal:** Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period.",
                        "• **Account Charges:** Your account will be charged for renewal within 24-hours prior to the end of the current period.",
                        "• **Management:** You can manage or turn off auto-renewal in your Apple ID Account Settings any time after purchase.",
                        "• **Free Trial:** Any unused portion of a free trial period, if offered, will be forfeited when the user purchases a subscription to that publication, where applicable."
                    ]
                )

                // Section 4
                sectionView(
                    title: "4. Limitation of Liability",
                    content: [
                        "The App is provided on an \"as is\" and \"as available\" basis. We do not guarantee that the QR code generation or scanning will be error-free 100% of the time. We are not liable for any damages resulting from the use of a QR code generated or scanned by the App (e.g., broken links, incorrect data)."
                    ]
                )

                // Section 5
                sectionView(
                    title: "5. Third-Party Links",
                    content: [
                        "The App may scan QR codes that link to third-party websites. We have no control over, and assume no responsibility for, the content, privacy policies, or practices of any third-party sites or services."
                    ]
                )

                // Section 6
                sectionView(
                    title: "6. Changes to Terms",
                    content: [
                        "We reserve the right to modify these Terms at any time. Your continued use of the App following any changes indicates your acceptance of the new Terms."
                    ]
                )

                // Section 7
                sectionView(
                    title: "7. Contact Information",
                    content: [
                        "If you have any questions or suggestions about our Terms of Use, do not hesitate to contact us at:",
                        "**Email:** buraksenturktr@icloud.com"
                    ]
                )

                Spacer(minLength: 40)
            }
            .padding(.horizontal, Theme.spacing.screen)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("Terms of Use")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Section View
    private func sectionView(title: String, content: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            ForEach(content, id: \.self) { text in
                if !text.isEmpty {
                    Text(parseMarkdown(text))
                        .font(.system(size: 15))
                        .foregroundStyle(Color.ink2)
                }
            }
        }
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
        TermsOfUseView()
    }
}
