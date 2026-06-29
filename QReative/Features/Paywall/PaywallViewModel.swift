import SwiftUI
import Combine
import RevenueCat

// MARK: - Paywall Feature
struct PaywallFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Paywall Plan (display model wrapping a RevenueCat Package)
struct PaywallPlan: Identifiable {
    let package: Package
    var id: String { package.identifier }

    let title: String          // "Yearly" / "Monthly" / "Weekly"
    let price: String          // localized total price, e.g. "₺499,99"
    let periodShort: String    // "/year"
    let perWeek: String?       // "≈ ₺9,60/week"
    let savings: String?       // "Save 48%"
    let trialDays: Int?        // free-trial length, if any
    let isBestValue: Bool
}

// MARK: - Paywall ViewModel
@MainActor
final class PaywallViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var plans: [PaywallPlan] = []
    @Published var selectedPlanID: String?
    @Published var isLoadingPlans: Bool = true
    @Published var isLoading: Bool = false           // purchase / restore in progress
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isPurchaseSuccessful: Bool = false

    // MARK: - Features
    let features: [PaywallFeature] = [
        PaywallFeature(
            icon: "eye.slash.fill",
            title: appLocalized("Ad-Free Experience"),
            description: appLocalized("Enjoy scanning without any interruptions")
        ),
        PaywallFeature(
            icon: "paintpalette.fill",
            title: appLocalized("Custom QR Designs"),
            description: appLocalized("Colors, gradients & unique patterns")
        ),
        PaywallFeature(
            icon: "sparkle",
            title: appLocalized("Logo & Emoji"),
            description: appLocalized("Add your brand logo or emoji to QR codes")
        ),
        PaywallFeature(
            icon: "qrcode",
            title: appLocalized("All QR Formats"),
            description: appLocalized("Wi-Fi, VCard, Instagram, WhatsApp & more")
        ),
        PaywallFeature(
            icon: "arrow.down.doc.fill",
            title: appLocalized("HD Export"),
            description: appLocalized("High-resolution QR code export")
        ),
        PaywallFeature(
            icon: "clock.arrow.circlepath",
            title: appLocalized("Unlimited History"),
            description: appLocalized("Keep all your scans and creations")
        )
    ]

    // MARK: - Dependencies
    private weak var coordinator: AppCoordinator?
    private let purchases = PurchasesManager.shared

    // MARK: - Computed
    var selectedPlan: PaywallPlan? {
        plans.first { $0.id == selectedPlanID }
    }

    var ctaButtonTitle: String {
        if isLoading { return appLocalized("Processing...") }
        if let days = selectedPlan?.trialDays, days > 0 {
            return appLocalized("Start free trial")
        }
        return appLocalized("Continue")
    }

    var footerText: String {
        guard let plan = selectedPlan else {
            return appLocalized("Auto-renews until canceled — cancel anytime in Settings.")
        }
        let priceLine = "\(plan.price)\(plan.periodShort)"
        if let days = plan.trialDays, days > 0 {
            return appLocalized("\(days)-day free trial, then \(priceLine). Auto-renews until canceled — cancel anytime in Settings.")
        }
        return appLocalized("\(priceLine). Auto-renews until canceled — cancel anytime in Settings.")
    }

    // MARK: - Init
    init(coordinator: AppCoordinator? = nil) {
        self.coordinator = coordinator
    }

    func bind(to coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Load Offerings
    func loadPlans() async {
        isLoadingPlans = true

        if purchases.offerings == nil {
            await purchases.loadOfferings()
        }

        let packages = purchases.offerings?.current?.availablePackages ?? []
        let eligibility = await purchases.introEligibility(for: packages)
        let built = Self.buildPlans(from: packages, eligibility: eligibility)

        plans = built
        selectedPlanID = built.first(where: { $0.isBestValue })?.id ?? built.first?.id
        isLoadingPlans = false
    }

    // MARK: - Selection
    func selectPlan(_ plan: PaywallPlan) {
        guard selectedPlanID != plan.id else { return }

        HapticManager.shared.impact(.light)

        withAnimation(Theme.animation.spring) {
            selectedPlanID = plan.id
        }
    }

    // MARK: - Purchase
    func startFreeTrial() async {
        guard !isLoading, let plan = selectedPlan else { return }

        isLoading = true
        showError = false

        do {
            let outcome = try await purchases.purchase(plan.package)
            isLoading = false

            switch outcome {
            case .purchased:
                AnalyticsService.purchaseCompleted(plan: plan.package.identifier)
                HapticManager.shared.success()
                completeAndDismiss()
            case .cancelled:
                break // user dismissed — nothing to show
            case .notEntitled:
                // Charged by Apple but the entitlement didn't activate — never
                // fail silently; point the user at Restore.
                showError = true
                errorMessage = appLocalized("Your purchase went through, but PRO couldn't be unlocked yet. Please try Restore.")
            }
        } catch {
            isLoading = false
            showError = true
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Restore
    func restorePurchases() async {
        guard !isLoading else { return }

        isLoading = true
        showError = false

        do {
            let restored = try await purchases.restore()
            isLoading = false
            AnalyticsService.restorePurchases(success: restored)

            if restored {
                HapticManager.shared.success()
                completeAndDismiss()
            } else {
                showError = true
                errorMessage = appLocalized("No purchases to restore")
            }
        } catch {
            isLoading = false
            showError = true
            errorMessage = error.localizedDescription
        }
    }

    func dismiss() {
        coordinator?.dismissPaywall()
    }

    // MARK: - Private
    private func completeAndDismiss() {
        isPurchaseSuccessful = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.coordinator?.handlePurchaseSuccess()
        }
    }

    // MARK: - Plan Building
    private static func buildPlans(
        from packages: [Package],
        eligibility: [String: IntroEligibilityStatus]
    ) -> [PaywallPlan] {
        let order: [PackageType] = [.annual, .sixMonth, .threeMonth, .twoMonth, .monthly, .weekly, .lifetime]
        let sorted = packages.sorted {
            (order.firstIndex(of: $0.packageType) ?? 99) < (order.firstIndex(of: $1.packageType) ?? 99)
        }

        // Highest per-week price (usually the weekly plan) anchors the savings %.
        let referencePerWeek = sorted.compactMap { perWeekValue(for: $0) }.max()

        return sorted.map { pkg in
            PaywallPlan(
                package: pkg,
                title: title(for: pkg),
                price: pkg.storeProduct.localizedPriceString,
                periodShort: periodShort(for: pkg),
                perWeek: perWeekString(for: pkg),
                savings: savings(for: pkg, referencePerWeek: referencePerWeek),
                trialDays: trialDays(for: pkg, eligibility: eligibility),
                isBestValue: pkg.packageType == .annual
            )
        }
    }

    private static func title(for pkg: Package) -> String {
        switch pkg.packageType {
        case .annual: return appLocalized("Yearly")
        case .sixMonth: return appLocalized("6 Months")
        case .threeMonth: return appLocalized("3 Months")
        case .twoMonth: return appLocalized("2 Months")
        case .monthly: return appLocalized("Monthly")
        case .weekly: return appLocalized("Weekly")
        case .lifetime: return appLocalized("Lifetime")
        default: return pkg.storeProduct.localizedTitle
        }
    }

    private static func periodShort(for pkg: Package) -> String {
        guard let unit = pkg.storeProduct.subscriptionPeriod?.unit else { return "" }
        switch unit {
        case .day: return appLocalized("/day")
        case .week: return appLocalized("/week")
        case .month: return appLocalized("/month")
        case .year: return appLocalized("/year")
        @unknown default: return ""
        }
    }

    /// Number of weeks in a subscription period (approximate, for price math).
    private static func weeks(in period: SubscriptionPeriod?) -> Double? {
        guard let period else { return nil }
        let value = Double(period.value)
        switch period.unit {
        case .day: return value / 7.0
        case .week: return value
        case .month: return value * 4.345
        case .year: return value * 52.143
        @unknown default: return nil
        }
    }

    private static func perWeekValue(for pkg: Package) -> Double? {
        guard let weeks = weeks(in: pkg.storeProduct.subscriptionPeriod), weeks > 0 else { return nil }
        return (pkg.storeProduct.price as NSDecimalNumber).doubleValue / weeks
    }

    private static func perWeekString(for pkg: Package) -> String? {
        guard pkg.packageType != .weekly,
              let perWeek = perWeekValue(for: pkg),
              let formatter = pkg.storeProduct.priceFormatter,
              let formatted = formatter.string(from: NSNumber(value: perWeek)) else {
            return nil
        }
        return "≈ \(formatted)\(appLocalized("/week"))"
    }

    private static func savings(for pkg: Package, referencePerWeek: Double?) -> String? {
        guard pkg.packageType != .weekly,
              let reference = referencePerWeek, reference > 0,
              let perWeek = perWeekValue(for: pkg) else {
            return nil
        }
        let percent = Int(((1 - perWeek / reference) * 100).rounded())
        guard percent >= 1 else { return nil }
        return appLocalized("Save \(percent)%")
    }

    private static func trialDays(for pkg: Package, eligibility: [String: IntroEligibilityStatus]) -> Int? {
        guard let intro = pkg.storeProduct.introductoryDiscount,
              intro.paymentMode == .freeTrial else {
            return nil
        }
        // Hide the trial only for users we know already used it.
        if eligibility[pkg.storeProduct.productIdentifier] == .ineligible {
            return nil
        }
        let period = intro.subscriptionPeriod
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        @unknown default: return nil
        }
    }
}
