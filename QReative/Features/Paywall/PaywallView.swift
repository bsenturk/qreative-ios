import SwiftUI

// MARK: - Paywall View
struct PaywallView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject private var viewModel = PaywallViewModel()
    @State private var showHero = false
    @State private var showContent = false
    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroSection
                            .opacity(showHero ? 1 : 0)
                            .offset(y: showHero ? 0 : 16)

                        featuresCard
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)

                        pricingSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }

                bottomBar
            }
        }
        .onAppear {
            viewModel.bind(to: appCoordinator)
            AnalyticsService.logScreen("paywall")
            startAnimations()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $showTerms) {
            legalSheet { TermsOfUseView() }
        }
        .sheet(isPresented: $showPrivacy) {
            legalSheet { PrivacyPolicyView() }
        }
    }

    // MARK: - Legal Sheet
    @ViewBuilder
    private func legalSheet<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        NavigationStack {
            content()
                .padding(.horizontal, 24)
                .background(Color.backgroundPrimary)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showTerms = false
                            showPrivacy = false
                        }
                    }
                }
        }
    }

    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.45)) { showHero = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.12)) { showContent = true }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                viewModel.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.ink3)
                    .frame(width: 32, height: 32)
                    .background(Color.surface2)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.accentPrimary.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: "crown.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.accentPrimary)
            }
            .shadow(color: Color.accentPrimary.opacity(0.25), radius: 20, x: 0, y: 10)

            Text("QREATIVE PRO")
                .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Color.accentPrimary)

            Text("Unlock the full\ncreative toolkit")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.6)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.textPrimary)

            ratingRow
        }
        .padding(.top, 4)
    }

    private var ratingRow: some View {
        HStack(spacing: 6) {
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.warning)
                }
            }
            Text("4.9 · loved by 50k+ creators")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.ink2)
        }
    }

    // MARK: - Features Card
    private var featuresCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.features.enumerated()), id: \.element.id) { index, feature in
                featureRow(feature, isLast: index == viewModel.features.count - 1)
            }
        }
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.lineColor, lineWidth: 1)
        }
        .shadow(color: Color.ink.opacity(0.05), radius: 16, x: 0, y: 8)
    }

    private func featureRow(_ feature: PaywallFeature, isLast: Bool) -> some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 11)
                .fill(Color.accentPrimary.opacity(0.12))
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: feature.icon)
                        .font(.system(size: 17))
                        .foregroundStyle(Color.accentPrimary)
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(feature.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundStyle(Color.textPrimary)
                Text(feature.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ink3)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.accentPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.lineColor)
                    .frame(height: 1)
                    .padding(.leading, 65)
            }
        }
    }

    // MARK: - Pricing
    private let orderedPlans: [SubscriptionPlan] = [.yearly, .monthly, .weekly]

    private var pricingSection: some View {
        VStack(spacing: 10) {
            ForEach(orderedPlans) { plan in
                PlanRow(
                    plan: plan,
                    isSelected: viewModel.selectedPlan == plan
                ) {
                    viewModel.selectPlan(plan)
                }
            }
        }
    }

    // MARK: - Bottom Bar (CTA + trust, thumb zone)
    private var bottomBar: some View {
        VStack(spacing: 12) {
            Button {
                Task { await viewModel.startFreeTrial() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(viewModel.ctaButtonTitle)
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.accentPrimary, Color.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color.accentPrimary.opacity(0.35), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(PressableStyle(scale: 0.98))
            .disabled(viewModel.isLoading)

            Text(viewModel.footerText)
                .font(.system(size: 11.5))
                .foregroundStyle(Color.ink3)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            HStack(spacing: 16) {
                Button("Restore") {
                    Task { await viewModel.restorePurchases() }
                }
                legalDivider
                Button("Terms") { showTerms = true }
                legalDivider
                Button("Privacy") { showPrivacy = true }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.ink3)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(
            Color.backgroundPrimary
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.lineColor)
                        .frame(height: 1)
                }
        )
    }

    private var legalDivider: some View {
        Circle()
            .fill(Color.ink3.opacity(0.5))
            .frame(width: 3, height: 3)
    }
}

// MARK: - Plan Row
private struct PlanRow: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.lightTap()
            action()
        } label: {
            HStack(spacing: 14) {
                radio

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(plan.period.capitalized)
                            .font(.system(size: 15.5, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)

                        if plan.isBestValue {
                            Text("BEST VALUE")
                                .font(.system(size: 9.5, weight: .bold))
                                .tracking(0.4)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentPrimary)
                                .clipShape(Capsule())
                        }
                    }

                    if let savings = plan.savings {
                        Text(savings)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.accentPrimary)
                    } else {
                        Text("Billed \(plan.periodShort)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.ink3)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(plan.price)
                            .font(.system(size: 17, weight: .bold))
                            .tracking(-0.4)
                            .foregroundStyle(Color.textPrimary)
                        Text(plan.periodShort)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.ink2)
                    }
                    if let weekly = plan.weeklyEquivalent {
                        Text(weekly)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.ink3)
                    }
                }
            }
            .padding(16)
            .background(isSelected ? Color.accentPrimary.opacity(0.06) : Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelected ? Color.accentPrimary : Color.lineColor,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }

    private var radio: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.accentPrimary : Color.lineStrong, lineWidth: 2)
                .frame(width: 22, height: 22)
            if isSelected {
                Circle()
                    .fill(Color.accentPrimary)
                    .frame(width: 22, height: 22)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PaywallView()
        .environmentObject(AppCoordinator())
}
