import SwiftUI
import Combine

// MARK: - Paywall Feature
struct PaywallFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Paywall ViewModel
@MainActor
final class PaywallViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var selectedPlan: SubscriptionPlan = .yearly
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isPurchaseSuccessful: Bool = false

    // MARK: - Properties
    let features: [PaywallFeature] = [
        PaywallFeature(
            icon: "eye.slash.fill",
            title: "Ad-Free Experience",
            description: "Enjoy scanning without any interruptions"
        ),
        PaywallFeature(
            icon: "paintpalette.fill",
            title: "Custom QR Designs",
            description: "Colors, gradients & unique patterns"
        ),
        PaywallFeature(
            icon: "sparkle",
            title: "Logo & Emoji",
            description: "Add your brand logo or emoji to QR codes"
        ),
        PaywallFeature(
            icon: "qrcode",
            title: "All QR Formats",
            description: "Wi-Fi, VCard, Instagram, Spotify & more"
        ),
        PaywallFeature(
            icon: "arrow.down.doc.fill",
            title: "HD Export",
            description: "High-resolution PNG, SVG & PDF export"
        ),
        PaywallFeature(
            icon: "clock.arrow.circlepath",
            title: "Unlimited History",
            description: "Save all scans with CSV export"
        )
    ]

    // MARK: - Dependencies
    private weak var coordinator: AppCoordinator?
    private var purchaseService: PurchaseServiceProtocol?

    // MARK: - Computed Properties
    var ctaButtonTitle: String {
        if isLoading {
            return "Processing..."
        }
        if selectedPlan.trialDays > 0 {
            return "Start \(selectedPlan.trialDays)-day free trial"
        }
        return "Continue"
    }

    var footerText: String {
        let plan = selectedPlan
        if plan.trialDays > 0 {
            return "\(plan.trialDays)-day free trial, then \(plan.price)/\(plan.period). Auto-renews until canceled — cancel anytime in Settings."
        }
        return "\(plan.price)/\(plan.period). Auto-renews until canceled — cancel anytime in Settings."
    }

    // MARK: - Init
    init(coordinator: AppCoordinator? = nil, purchaseService: PurchaseServiceProtocol? = nil) {
        self.coordinator = coordinator
        self.purchaseService = purchaseService
    }

    // MARK: - Methods
    func selectPlan(_ plan: SubscriptionPlan) {
        guard selectedPlan != plan else { return }

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(Theme.animation.spring) {
            selectedPlan = plan
        }
    }

    func startFreeTrial() async {
        guard !isLoading else { return }

        isLoading = true
        showError = false

        do {
            if let service = purchaseService {
                try await service.purchase(selectedPlan)
                handlePurchaseResult(true)
            } else {
                try await Task.sleep(nanoseconds: 1_500_000_000)
                handlePurchaseResult(true)
            }
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func restorePurchases() async {
        guard !isLoading else { return }

        isLoading = true
        showError = false

        do {
            if let service = purchaseService {
                try await service.restorePurchases()
                let isPremium = await service.checkSubscriptionStatus()
                AnalyticsService.restorePurchases(success: isPremium)
                if isPremium {
                    handlePurchaseResult(true)
                } else {
                    showError = true
                    errorMessage = "No purchases to restore"
                    isLoading = false
                }
            } else {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                AnalyticsService.restorePurchases(success: false)
                showError = true
                errorMessage = "No purchases to restore"
                isLoading = false
            }
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func dismiss() {
        coordinator?.dismissPaywall()
    }

    // MARK: - Private Methods
    private func handlePurchaseResult(_ success: Bool) {
        isLoading = false

        if success {
            isPurchaseSuccessful = true
            AnalyticsService.purchaseCompleted(plan: selectedPlan.period)
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.coordinator?.handlePurchaseSuccess()
            }
        }
    }

    // MARK: - Coordinator Binding
    func bind(to coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
}
