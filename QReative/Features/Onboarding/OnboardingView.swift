import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var currentPage: Int = 0
    @State private var floatOffset: CGFloat = 0
    @State private var isAppeared = false
    @State private var showContent = false
    @State private var showButton = false

    private let totalPages = 3

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Content
            VStack(spacing: 0) {
                Spacer()

                // 3D QR Code
                qrCodeSection
                    .padding(.bottom, 48)
                    .scaleEffect(isAppeared ? 1 : 0.5)
                    .opacity(isAppeared ? 1 : 0)

                // Text Content
                textSection
                    .padding(.horizontal, Theme.spacing.screen)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)

                Spacer()

                // Page Indicators
                pageIndicators
                    .padding(.bottom, 32)
                    .opacity(showContent ? 1 : 0)

                // Get Started Button
                PrimaryButton("Get Started", icon: "arrow.right") {
                    HapticManager.shared.mediumTap()
                    appCoordinator.completeOnboarding()
                }
                .frame(maxWidth: 320)
                .padding(.horizontal, Theme.spacing.screen)
                .padding(.bottom, 60)
                .scaleEffect(showButton ? 1 : 0.8)
                .opacity(showButton ? 1 : 0)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Base background
            Color.backgroundPrimary

            // Purple orb - top left
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.accentPrimary.opacity(0.6),
                            Color.accentPrimary.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: -150, y: -200)

            // Cyan orb - bottom right
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.accentTertiary.opacity(0.5),
                            Color.accentTertiary.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 60)
                .offset(x: 150, y: 300)
        }
    }

    // MARK: - QR Code Section

    private var qrCodeSection: some View {
        QRCodePreview(
            content: "https://qreative.app",
            size: 180,
            foregroundColor: .accentPrimary,
            backgroundColor: .white,
            shape: .rounded,
            logoImage: nil,
            isGlowing: true
        )
        .rotation3DEffect(
            .degrees(10),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
        .rotation3DEffect(
            .degrees(-10),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .offset(y: floatOffset)
        .shadow(color: Color.accentPrimary.opacity(0.3), radius: 30, x: 0, y: 20)
    }

    // MARK: - Text Section

    private var textSection: some View {
        VStack(spacing: 16) {
            Text(headlineText)
                .typography(.largeTitle)
                .multilineTextAlignment(.center)

            Text(subheadlineText)
                .typography(.body, color: .textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Page Content

    private var headlineText: String {
        switch currentPage {
        case 0:
            return "Create Unique QR Codes"
        case 1:
            return "Scan Anything Instantly"
        case 2:
            return "Share with Style"
        default:
            return "Create Unique QR Codes"
        }
    }

    private var subheadlineText: String {
        switch currentPage {
        case 0:
            return "Customize colors, shapes, and logos."
        case 1:
            return "Fast and accurate QR code scanning."
        case 2:
            return "Export in high quality formats."
        default:
            return "Customize colors, shapes, and logos."
        }
    }

    // MARK: - Page Indicators

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.accentPrimary : Color.white.opacity(0.2))
                    .frame(
                        width: index == currentPage ? 24 : 6,
                        height: 6
                    )
                    .animation(Theme.animation.spring, value: currentPage)
            }
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // QR Code appear
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            isAppeared = true
        }

        // Text fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            showContent = true
        }

        // Button appear
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
            showButton = true
        }

        // Start floating animation
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(0.6)) {
            floatOffset = -12
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(AppCoordinator())
}
