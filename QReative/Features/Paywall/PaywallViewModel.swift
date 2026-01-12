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
            icon: "crown.fill",
            title: "Custom Logos",
            description: "Add your brand logo to QR codes"
        ),
        PaywallFeature(
            icon: "infinity",
            title: "Unlimited Scans",
            description: "No daily limits on scanning"
        ),
        PaywallFeature(
            icon: "eye.slash.fill",
            title: "No Ads",
            description: "Distraction-free experience"
        ),
        PaywallFeature(
            icon: "sparkles",
            title: "Premium Designs",
            description: "Exclusive templates and styles"
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
        return "Start Free Trial"
    }

    var footerText: String {
        let plan = selectedPlan
        return "\(plan.trialDays)-day free trial, then \(plan.price)/\(plan.period). Cancel anytime."
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
                if isPremium {
                    handlePurchaseResult(true)
                } else {
                    showError = true
                    errorMessage = "No purchases to restore"
                    isLoading = false
                }
            } else {
                try await Task.sleep(nanoseconds: 1_000_000_000)
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
