import SwiftUI

// MARK: - Paywall View

struct PaywallView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject private var viewModel = PaywallViewModel()
    @State private var showHeader = false
    @State private var showFeatures = false
    @State private var showPricing = false
    @State private var showCTA = false

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                        .padding(.top, 20)
                        .opacity(showHeader ? 1 : 0)
                        .offset(y: showHeader ? 0 : 20)

                    // Features Card
                    featuresCard
                        .padding(.horizontal, Theme.spacing.screen)
                        .opacity(showFeatures ? 1 : 0)
                        .offset(y: showFeatures ? 0 : 30)

                    // Pricing Options
                    pricingSection
                        .padding(.horizontal, Theme.spacing.screen)
                        .opacity(showPricing ? 1 : 0)
                        .offset(y: showPricing ? 0 : 30)

                    // CTA Button
                    ctaSection
                        .padding(.horizontal, Theme.spacing.screen)
                        .opacity(showCTA ? 1 : 0)
                        .scaleEffect(showCTA ? 1 : 0.9)

                    // Footer
                    footerSection
                        .padding(.bottom, 40)
                        .opacity(showCTA ? 1 : 0)
                }
            }

            // Close Button
            closeButton
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.bind(to: appCoordinator)
            startAnimations()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.4)) {
            showHeader = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
            showFeatures = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            showPricing = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.45)) {
            showCTA = true
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color.backgroundPrimary

            // Purple gradient orb at top
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.accentPrimary.opacity(0.5),
                            Color.accentPrimary.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 40)
                .offset(y: -200)
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    viewModel.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .glassCardSubtle(cornerRadius: 10)
                }
                .padding(.trailing, Theme.spacing.screen)
                .padding(.top, 60)
            }
            Spacer()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // PRO Badge
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                Text("PRO")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(Color.warning)
            .padding(.top, 40)

            // Title
            Text("Unlock QReative PRO")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            // Subtitle
            Text("Get unlimited access to all features")
                .typography(.body, color: .textSecondary)
        }
    }

    // MARK: - Features Card

    private var featuresCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.features.enumerated()), id: \.element.id) { index, feature in
                featureRow(feature)

                if index < viewModel.features.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.06))
                        .padding(.leading, 52)
                }
            }
        }
        .padding(.vertical, 8)
        .glassCard()
    }

    private func featureRow(_ feature: PaywallFeature) -> some View {
        HStack(spacing: 12) {
            // Green checkmark
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.success.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.success)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Text(feature.description)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        HStack(spacing: 12) {
            ForEach(SubscriptionPlan.allCases) { plan in
                PricingCard(
                    plan: plan,
                    isSelected: viewModel.selectedPlan == plan
                ) {
                    viewModel.selectPlan(plan)
                }
            }
        }
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: 16) {
            PrimaryButton(
                viewModel.ctaButtonTitle,
                icon: viewModel.isLoading ? nil : "arrow.right",
                isLoading: viewModel.isLoading
            ) {
                Task {
                    await viewModel.startFreeTrial()
                }
            }

            // Restore Purchases
            Button {
                Task {
                    await viewModel.restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .typography(.callout, color: .textTertiary)
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.footerText)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.4))
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Terms of Use") {}
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.3))

                Button("Privacy Policy") {}
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
    }
}

// MARK: - Pricing Card

private struct PricingCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.lightTap()
            action()
        } label: {
            VStack(spacing: 8) {
                // Best Value Badge
                if plan.isBestValue {
                    Text("BEST VALUE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentPrimary)
                        .clipShape(Capsule())
                } else {
                    // Spacer for alignment
                    Text(" ")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .opacity(0)
                }

                // Period
                Text(plan.period.capitalized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))

                // Price
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(plan.price)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text(plan.periodShort)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.5))
                }

                // Savings
                if let savings = plan.savings {
                    Text(savings)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.success)
                } else {
                    Text(" ")
                        .font(.system(size: 11))
                        .opacity(0)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                if plan.isBestValue {
                    LinearGradient.purpleGradient
                        .opacity(isSelected ? 1 : 0.5)
                } else {
                    Color.white.opacity(0.05)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.accentPrimary : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .scaleEffect(isSelected ? 1.02 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(PressableStyle(scale: 0.96))
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environmentObject(AppCoordinator())
}
