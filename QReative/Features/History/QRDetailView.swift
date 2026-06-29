import SwiftUI

// MARK: - QR Detail View
/// Shows a history item as a rendered QR code with its content and quick
/// actions (open / copy / share). Replaces the old debug placeholder.
struct QRDetailView: View {
    let historyItemId: String

    @EnvironmentObject private var tabCoordinator: MainTabCoordinator
    @ObservedObject private var storage = StorageService.shared
    @State private var isCopied = false

    private var item: HistoryItem? {
        storage.historyItems.first { $0.id.uuidString == historyItemId }
    }

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            if let item {
                content(for: item)
            } else {
                notFound
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { AnalyticsService.logScreen("qr_detail") }
    }

    // MARK: - Content
    private func content(for item: HistoryItem) -> some View {
        VStack(spacing: 0) {
            navigationBar(title: item.displayTypeName)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    qrCard(for: item)
                        .padding(.top, 8)

                    contentCard(for: item)

                    actions(for: item)
                }
                .padding(.horizontal, Theme.spacing.screen)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Navigation Bar
    private func navigationBar(title: String) -> some View {
        HStack {
            Button {
                tabCoordinator.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(scale: 0.9))

            Spacer()

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .tracking(-0.2)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .frame(height: 44)
        .padding(.horizontal, Theme.spacing.screen)
        .padding(.top, 8)
    }

    // MARK: - QR Card
    private func qrCard(for item: HistoryItem) -> some View {
        VStack(spacing: 16) {
            codePreview(for: item)

            HStack(spacing: 8) {
                Image(systemName: item.displayTypeIcon)
                    .font(.system(size: 13, weight: .semibold))
                Text(item.displayTypeName)
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.2)
            }
            .foregroundStyle(Color.ink2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.lineColor, lineWidth: 1)
        }
        .shadow(color: Color.ink.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    /// Renders the scanned/created code: a real barcode image for barcode and
    /// 2D non-QR symbologies, otherwise the styled QR preview.
    @ViewBuilder
    private func codePreview(for item: HistoryItem) -> some View {
        if let symbology = item.symbology, symbology != .qr,
           let barcode = BarcodeGenerator.image(for: item.content, symbology: symbology) {
            let isWide = BarcodeGenerator.isWide(symbology)
            Image(uiImage: barcode)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 250, height: isWide ? 130 : 230)
                .padding(.horizontal, isWide ? 8 : 0)
        } else {
            QRCodePreview(
                content: item.content,
                size: 230,
                foregroundColor: qrColor(for: item),
                backgroundColor: .white,
                shape: qrShape(for: item),
                logoImage: nil,
                isGlowing: false
            )
            .frame(width: 230, height: 230)
        }
    }

    // MARK: - Content Card
    private func contentCard(for item: HistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Content")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .textCase(.uppercase)
                .tracking(0.5)
                .foregroundStyle(Color.ink3)

            Text(item.content)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.formattedDate)
                .font(.system(size: 12.5))
                .foregroundStyle(Color.ink3)
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.lineColor, lineWidth: 1)
        }
    }

    // MARK: - Actions
    private func actions(for item: HistoryItem) -> some View {
        VStack(spacing: 10) {
            if let url = openableURL(for: item) {
                PrimaryButton(openTitle(for: item.type), icon: "arrow.up.right") {
                    UIApplication.shared.open(url)
                }
            }

            HStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = item.content
                    HapticManager.shared.success()
                    withAnimation { isCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { isCopied = false }
                    }
                } label: {
                    secondaryLabel(
                        icon: isCopied ? "checkmark" : "doc.on.doc",
                        title: isCopied ? appLocalized("Copied") : appLocalized("Copy"),
                        tint: isCopied ? Color.success : Color.textPrimary
                    )
                }

                ShareLink(item: item.content) {
                    secondaryLabel(
                        icon: "square.and.arrow.up",
                        title: appLocalized("Share"),
                        tint: Color.textPrimary
                    )
                }
            }
        }
    }

    private func secondaryLabel(icon: String, title: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.lineColor, lineWidth: 1)
        }
    }

    // MARK: - Not Found
    private var notFound: some View {
        VStack(spacing: 0) {
            navigationBar(title: appLocalized("QR Code"))

            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "qrcode")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.ink3)
                Text("This item is no longer available.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.ink2)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Helpers
    private func qrShape(for item: HistoryItem) -> QRShape {
        QRShape(rawValue: item.customShape ?? "") ?? .rounded
    }

    private func qrColor(for item: HistoryItem) -> Color {
        if let hex = item.customColor, !hex.isEmpty {
            return Color(hex: hex)
        }
        return Color.ink
    }

    private func openTitle(for type: HistoryItemType) -> String {
        switch type {
        case .website: return appLocalized("Open URL")
        case .instagram: return appLocalized("Open in Instagram")
        case .whatsapp: return appLocalized("Open in WhatsApp")
        case .email: return appLocalized("Send Email")
        case .phone: return appLocalized("Call")
        case .sms: return appLocalized("Send Message")
        default: return appLocalized("Open")
        }
    }

    /// Builds an openable URL for actionable types, or `nil` if there's nothing
    /// meaningful to open.
    private func openableURL(for item: HistoryItem) -> URL? {
        let content = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
        switch item.type {
        case .website, .instagram, .whatsapp:
            if content.lowercased().hasPrefix("http://") || content.lowercased().hasPrefix("https://") {
                return URL(string: content)
            }
            return URL(string: "https://\(content)")
        case .email:
            let address = content.hasPrefix("mailto:") ? content : "mailto:\(content)"
            return URL(string: address)
        case .phone:
            let number = content.hasPrefix("tel:") ? content : "tel:\(content.replacingOccurrences(of: " ", with: ""))"
            return URL(string: number)
        case .sms:
            let number = content.hasPrefix("sms:") ? content : "sms:\(content)"
            return URL(string: number)
        case .wifi, .vcard, .text, .unknown:
            return nil
        }
    }
}
