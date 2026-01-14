import SwiftUI

// MARK: - QR Type Grid Item
struct QRTypeGridItem: View {
    let template: QRTypeTemplate
    let isPremiumUser: Bool
    let onTap: () -> Void

    @State private var isPressed: Bool = false
    @State private var isHovered: Bool = false

    private var shouldShowPremiumBadge: Bool {
        template.isPremium && !isPremiumUser
    }

    var body: some View {
        Button {
            triggerHaptic()
            onTap()
        } label: {
            VStack(spacing: 12) {
                iconContainer

                VStack(spacing: 4) {
                    Text(template.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)

                    if shouldShowPremiumBadge {
                        premiumBadge
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isHovered ? 0.08 : 0.05))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.animation.springQuick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                    isHovered = true
                }
                .onEnded { _ in
                    isPressed = false
                    isHovered = false
                }
        )
    }

    // MARK: - Icon Container
    private var iconContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(template.gradient)
                .frame(width: 56, height: 56)
                .shadow(
                    color: template.gradientColors.first?.opacity(0.4) ?? .clear,
                    radius: 12,
                    x: 0,
                    y: 4
                )

            Image(systemName: template.icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Premium Badge
    private var premiumBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 8))

            Text("PRO")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(Color.warning)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background {
            Capsule()
                .fill(Color.warning.opacity(0.15))
        }
    }

    // MARK: - Haptic
    private func triggerHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
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

// MARK: - Large QR Type Card (for featured items)
struct QRTypeLargeCard: View {
    let template: QRTypeTemplate
    let isPremiumUser: Bool
    let onTap: () -> Void

    @State private var isPressed: Bool = false

    private var shouldShowPremiumBadge: Bool {
        template.isPremium && !isPremiumUser
    }

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(template.gradient)
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: template.gradientColors.first?.opacity(0.3) ?? .clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )

                    Image(systemName: template.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(template.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)

                        if shouldShowPremiumBadge {
                            HStack(spacing: 3) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 8))
                                Text("PRO")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(Color.warning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background {
                                Capsule()
                                    .fill(Color.warning.opacity(0.15))
                            }
                        }
                    }

                    Text(template.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.animation.springQuick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview
#Preview("Grid Item") {
    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: 20) {
            QRTypeGrid(templates: QRTypeTemplate.allTemplates, isPremiumUser: false) { template in
                print("Selected: \(template.title)")
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview("Large Card") {
    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: 12) {
            ForEach(QRTypeTemplate.allTemplates.prefix(3)) { template in
                QRTypeLargeCard(template: template, isPremiumUser: false) {
                    print("Selected: \(template.title)")
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
