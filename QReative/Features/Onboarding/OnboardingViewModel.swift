import SwiftUI
import Combine

// MARK: - Onboarding Page
struct OnboardingPage: Identifiable {
    let id: Int
    let headline: String
    let subheadline: String
    let icon: String
    let qrShape: QRShape
}

// MARK: - Onboarding ViewModel
@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var currentPage: Int = 0
    @Published var isAnimating: Bool = false

    // MARK: - Properties
    let totalPages: Int = 3

    let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            headline: "Create Unique QR Codes",
            subheadline: "Customize colors, shapes, and logos.",
            icon: "qrcode.viewfinder",
            qrShape: .rounded
        ),
        OnboardingPage(
            id: 1,
            headline: "Scan Anything Instantly",
            subheadline: "Fast and accurate QR code scanning.",
            icon: "viewfinder",
            qrShape: .dots
        ),
        OnboardingPage(
            id: 2,
            headline: "Share with Style",
            subheadline: "Export in high quality formats.",
            icon: "square.and.arrow.up",
            qrShape: .squares
        )
    ]

    // MARK: - Coordinator Reference
    private weak var coordinator: AppCoordinator?

    // MARK: - Computed Properties
    var currentPageData: OnboardingPage {
        pages[currentPage]
    }

    var isLastPage: Bool {
        currentPage == totalPages - 1
    }

    var isFirstPage: Bool {
        currentPage == 0
    }

    var progress: CGFloat {
        CGFloat(currentPage + 1) / CGFloat(totalPages)
    }

    // MARK: - Init
    init(coordinator: AppCoordinator? = nil) {
        self.coordinator = coordinator
    }

    // MARK: - Methods
    func nextPage() {
        guard !isAnimating else { return }

        if isLastPage {
            completeOnboarding()
        } else {
            isAnimating = true
            withAnimation(Theme.animation.spring) {
                currentPage += 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isAnimating = false
            }
        }
    }

    func previousPage() {
        guard !isAnimating, !isFirstPage else { return }

        isAnimating = true
        withAnimation(Theme.animation.spring) {
            currentPage -= 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isAnimating = false
        }
    }

    func goToPage(_ page: Int) {
        guard page >= 0, page < totalPages, page != currentPage else { return }

        withAnimation(Theme.animation.spring) {
            currentPage = page
        }
    }

    func completeOnboarding() {
        coordinator?.completeOnboarding()
    }

    func skipOnboarding() {
        coordinator?.skipOnboarding()
    }

    // MARK: - Coordinator Binding
    func bind(to coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
}

// MARK: - Environment Key
private struct OnboardingViewModelKey: EnvironmentKey {
    static let defaultValue = OnboardingViewModel()
}

extension EnvironmentValues {
    var onboardingViewModel: OnboardingViewModel {
        get { self[OnboardingViewModelKey.self] }
        set { self[OnboardingViewModelKey.self] = newValue }
    }
}
