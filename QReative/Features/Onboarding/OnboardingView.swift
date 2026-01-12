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
            backgroundLayer

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        pageContent(for: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, _ in
                    HapticManager.shared.lightTap()
                }

                pageIndicators
                    .padding(.bottom, 32)
                    .opacity(showContent ? 1 : 0)

                PrimaryButton(currentPage == totalPages - 1 ? "Get Started" : "Next", icon: "arrow.right") {
                    HapticManager.shared.mediumTap()
                    if currentPage < totalPages - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        appCoordinator.completeOnboarding()
                    }
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

    // MARK: - Page Content
    private func pageContent(for index: Int) -> some View {
        VStack(spacing: 0) {
            Spacer()

            pageIcon(for: index)
                .padding(.bottom, 48)
                .scaleEffect(isAppeared ? 1 : 0.5)
                .opacity(isAppeared ? 1 : 0)

            VStack(spacing: 16) {
                Text(headlineText(for: index))
                    .typography(.largeTitle)
                    .multilineTextAlignment(.center)

                Text(subheadlineText(for: index))
                    .typography(.body, color: .textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.horizontal, Theme.spacing.screen)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)

            Spacer()
        }
    }

    // MARK: - Page Icon
    @ViewBuilder
    private func pageIcon(for index: Int) -> some View {
        switch index {
        case 0:
            qrCodeSection
        case 1:
            scanIconSection
        case 2:
            historyIconSection
        default:
            qrCodeSection
        }
    }

    // MARK: - Scan Icon Section
    private var scanIconSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [Color.accentPrimary, Color.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 180)

            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(.white)
        }
        .offset(y: floatOffset)
        .shadow(color: Color.accentPrimary.opacity(0.3), radius: 30, x: 0, y: 20)
    }

    // MARK: - History Icon Section
    private var historyIconSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [Color.accentTertiary, Color.accentPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 180)

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(.white)
        }
        .offset(y: floatOffset)
        .shadow(color: Color.accentTertiary.opacity(0.3), radius: 30, x: 0, y: 20)
    }

    // MARK: - Background Layer
    private var backgroundLayer: some View {
        ZStack {
            Color.backgroundPrimary

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

    // MARK: - Page Texts
    private func headlineText(for index: Int) -> String {
        switch index {
        case 0:
            return "Create Unique QR Codes"
        case 1:
            return "Scan in Seconds"
        case 2:
            return "Access Your History"
        default:
            return "Create Unique QR Codes"
        }
    }

    private func subheadlineText(for index: Int) -> String {
        switch index {
        case 0:
            return "Design beautiful QR codes with custom colors, shapes, and your own logo."
        case 1:
            return "Instantly scan any QR code with our fast and accurate scanner."
        case 2:
            return "Access all your previously scanned codes anytime, anywhere."
        default:
            return "Design beautiful QR codes with custom colors, shapes, and your own logo."
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
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            isAppeared = true
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            showContent = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
            showButton = true
        }

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
