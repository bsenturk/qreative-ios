import Foundation
import Combine

// MARK: - Subscription Plan

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case weekly = "com.qreative.premium.weekly"
    case monthly = "com.qreative.premium.monthly"
    case yearly = "com.qreative.premium.yearly"
    case lifetime = "com.qreative.premium.lifetime"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    var description: String {
        switch self {
        case .weekly: return "Billed weekly"
        case .monthly: return "Billed monthly"
        case .yearly: return "Billed yearly"
        case .lifetime: return "One-time purchase"
        }
    }

    var price: String {
        switch self {
        case .weekly: return "$2.99"
        case .monthly: return "$7.99"
        case .yearly: return "$49.99"
        case .lifetime: return "$99.99"
        }
    }

    var savings: String? {
        switch self {
        case .weekly: return nil
        case .monthly: return nil
        case .yearly: return "Save 48%"
        case .lifetime: return "Best Value"
        }
    }

    var isPopular: Bool {
        self == .yearly
    }
}

// MARK: - Purchase Error

enum PurchaseError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case purchaseCancelled
    case verificationFailed
    case networkError
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .purchaseCancelled:
            return "Purchase was cancelled"
        case .verificationFailed:
            return "Purchase verification failed"
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Purchase Service Protocol

protocol PurchaseServiceProtocol: AnyObject {
    var isPremium: Bool { get }
    var isPremiumPublisher: AnyPublisher<Bool, Never> { get }

    func purchase(_ plan: SubscriptionPlan) async throws
    func restorePurchases() async throws
    func checkSubscriptionStatus() async -> Bool
}

// MARK: - Mock Purchase Service (Development)

@MainActor
final class MockPurchaseService: PurchaseServiceProtocol, ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var isPremium: Bool = false

    // MARK: - Publishers

    var isPremiumPublisher: AnyPublisher<Bool, Never> {
        $isPremium.eraseToAnyPublisher()
    }

    // MARK: - Constants

    private let premiumKey = "com.qreative.isPremium"
    private let purchaseDateKey = "com.qreative.purchaseDate"
    private let planKey = "com.qreative.purchasedPlan"

    // MARK: - Singleton

    static let shared = MockPurchaseService()

    // MARK: - Init

    private init() {
        loadPremiumStatus()
    }

    // MARK: - Load Status

    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: premiumKey)
    }

    // MARK: - Purchase

    func purchase(_ plan: SubscriptionPlan) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000)

        // Simulate random failure (10% chance)
        if Int.random(in: 1...10) == 1 {
            throw PurchaseError.purchaseFailed
        }

        // Save purchase
        UserDefaults.standard.set(true, forKey: premiumKey)
        UserDefaults.standard.set(Date(), forKey: purchaseDateKey)
        UserDefaults.standard.set(plan.rawValue, forKey: planKey)

        isPremium = true
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Check if there was a previous purchase
        if UserDefaults.standard.object(forKey: purchaseDateKey) != nil {
            isPremium = true
            UserDefaults.standard.set(true, forKey: premiumKey)
        } else {
            // No purchases to restore
            isPremium = false
        }
    }

    // MARK: - Check Subscription Status

    func checkSubscriptionStatus() async -> Bool {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        return isPremium
    }

    // MARK: - Debug Methods

    #if DEBUG
    func debugSetPremium(_ value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: premiumKey)
        if !value {
            UserDefaults.standard.removeObject(forKey: purchaseDateKey)
            UserDefaults.standard.removeObject(forKey: planKey)
        }
    }

    func debugGetPurchaseInfo() -> (date: Date?, plan: String?) {
        let date = UserDefaults.standard.object(forKey: purchaseDateKey) as? Date
        let plan = UserDefaults.standard.string(forKey: planKey)
        return (date, plan)
    }

    func debugClearAllPurchases() {
        isPremium = false
        UserDefaults.standard.removeObject(forKey: premiumKey)
        UserDefaults.standard.removeObject(forKey: purchaseDateKey)
        UserDefaults.standard.removeObject(forKey: planKey)
    }
    #endif
}

// MARK: - Purchase Service Factory

enum PurchaseServiceFactory {
    static func create() -> any PurchaseServiceProtocol {
        // TODO: Return StoreKitPurchaseService for production
        return MockPurchaseService.shared
    }
}
