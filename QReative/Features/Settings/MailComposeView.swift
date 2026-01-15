import SwiftUI
import MessageUI

// MARK: - Mail Compose View
struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    let recipient: String
    let subject: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipient])
        composer.setSubject(subject)

        // Add app info to body
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let systemVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model

        let body = """



        ---
        App Version: \(appVersion)
        iOS Version: \(systemVersion)
        Device: \(deviceModel)
        """
        composer.setMessageBody(body, isHTML: false)

        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        private let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            dismiss()
        }
    }
}

// MARK: - Mail Unavailable View
struct MailUnavailableView: View {
    @Environment(\.dismiss) private var dismiss
    let recipient: String

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.accentPrimary)

                    VStack(spacing: 12) {
                        Text("Mail Not Configured")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("Please configure your Mail app or contact us directly at:")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Text(recipient)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.accentPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            }
                            .onTapGesture {
                                UIPasteboard.general.string = recipient
                                HapticManager.shared.lightTap()
                            }

                        Text("Tap to copy")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.accentPrimary)
                            }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
            }
        }
    }
}
