import SwiftUI

// MARK: - QR Type Grid Item
struct QRTypeGridItem: View {
    let template: QRTypeTemplate
    let isPremiumUser: Bool
    let onTap: () -> Void

    private var shouldShowPremiumBadge: Bool {
        template.isPremium && !isPremiumUser
    }

    var body: some View {
        Button {
            triggerHaptic()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Icon container
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.ink)
                    .frame(width: 46, height: 46)
                    .overlay {
                        Image(systemName: template.icon)
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(Color.backgroundPrimary)
                    }
                    .padding(.bottom, 30)

                // Title
                Text(template.title)
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(Color.textPrimary)

                // Subtitle
                Text(template.subtitle)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.ink3)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.lineColor, lineWidth: 1)
            }
            .overlay(alignment: .topTrailing) {
                if shouldShowPremiumBadge {
                    proBadge.padding(12)
                }
            }
            .shadow(color: Color.ink.opacity(0.04), radius: 2, x: 0, y: 1)
            .shadow(color: Color.ink.opacity(0.08), radius: 16, x: 0, y: 6)
        }
        .buttonStyle(PressableStyle(scale: 0.97))
        .accessibilityIdentifier("qrType.\(template.id)")
    }

    // MARK: - Pro Badge
    private var proBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
                .font(.system(size: 9))
            Text("PRO")
                .font(.system(size: 9.5, weight: .bold))
        }
        .foregroundStyle(Color.accentPrimary)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.accentPrimary.opacity(0.12))
        .clipShape(Capsule())
    }

    private func triggerHaptic() {
        HapticManager.shared.impact(.light)
    }
}

// MARK: - QR Type Grid
struct QRTypeGrid: View {
    let templates: [QRTypeTemplate]
    let isPremiumUser: Bool
    let onSelect: (QRTypeTemplate) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(templates) { template in
                QRTypeGridItem(template: template, isPremiumUser: isPremiumUser) {
                    onSelect(template)
                }
            }
        }
    }
}

// MARK: - Large QR Type Card (for More sheet)
struct QRTypeLargeCard: View {
    let template: QRTypeTemplate
    let isPremiumUser: Bool
    let onTap: () -> Void

    private var shouldShowPremiumBadge: Bool {
        template.isPremium && !isPremiumUser
    }

    var body: some View {
        Button {
            HapticManager.shared.impact(.light)
            onTap()
        } label: {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.ink)
                    .frame(width: 46, height: 46)
                    .overlay {
                        Image(systemName: template.icon)
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(Color.backgroundPrimary)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(template.title)
                            .font(.system(size: 16, weight: .semibold))
                            .tracking(-0.3)
                            .foregroundStyle(Color.textPrimary)

                        if shouldShowPremiumBadge {
                            HStack(spacing: 3) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 9))
                                Text("PRO")
                                    .font(.system(size: 9.5, weight: .bold))
                            }
                            .foregroundStyle(Color.accentPrimary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.accentPrimary.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }

                    Text(template.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.ink3)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ink3)
            }
            .padding(16)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.lineColor, lineWidth: 1)
            }
            .shadow(color: Color.ink.opacity(0.04), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }
}
