import Foundation
import Combine
import RevenueCat

/// Thin wrapper around the RevenueCat SDK.
///
/// Holds the single source of truth for subscription state (`isPro`) and keeps
/// the app's `AppCoordinator.isPremiumUser` flag in sync so all existing PRO
/// gating keeps working. The SDK is configured in `QReativeApp.init()`; call
/// `start(coordinator:)` once after that to begin observing entitlements.
@MainActor
final class PurchasesManager: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = PurchasesManager()

    /// 🔧 Change this to match the Entitlement identifier you create in the
    /// RevenueCat dashboard (Project → Entitlements).
    static let entitlementID = "premium"

    // MARK: - Published State
    @Published private(set) var isPro = false
    @Published private(set) var offerings: Offerings?

    private weak var coordinator: AppCoordinator?

    private override init() {
        super.init()
    }

    // MARK: - Lifecycle
    /// Call once, after `Purchases.configure(...)`, passing the app coordinator
    /// so entitlement changes propagate to `isPremiumUser`.
    func start(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        Purchases.shared.delegate = self
        Task { await refreshCustomerInfo() }
        Task { await loadOfferings() }
    }

    // MARK: - Customer Info / Entitlements
    func refreshCustomerInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            apply(info)
        } catch {
            print("RevenueCat customerInfo error: \(error.localizedDescription)")
        }
    }

    // MARK: - Offerings
    func loadOfferings() async {
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            print("RevenueCat offerings error: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase
    /// Returns `true` if the purchase completed and the `premium` entitlement is
    /// now active, `false` if the user cancelled. Throws on real failures.
    @discardableResult
    func purchase(_ package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        if result.userCancelled { return false }
        apply(result.customerInfo)
        return isPro
    }

    // MARK: - Restore
    @discardableResult
    func restore() async throws -> Bool {
        let info = try await Purchases.shared.restorePurchases()
        apply(info)
        return isPro
    }

    // MARK: - Account Linking (only if you add user accounts later)
    func logIn(_ appUserID: String) async {
        do {
            let (info, _) = try await Purchases.shared.logIn(appUserID)
            apply(info)
        } catch {
            print("RevenueCat logIn error: \(error.localizedDescription)")
        }
    }

    func logOut() async {
        do {
            let info = try await Purchases.shared.logOut()
            apply(info)
        } catch {
            print("RevenueCat logOut error: \(error.localizedDescription)")
        }
    }

    // MARK: - Private
    private func apply(_ info: CustomerInfo) {
        let active = info.entitlements[Self.entitlementID]?.isActive == true
        isPro = active
        coordinator?.updatePremium(active)
    }
}

// MARK: - PurchasesDelegate (live entitlement updates)
extension PurchasesManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.apply(customerInfo)
        }
    }
}
