import SwiftUI

// MARK: - Onboarding View
/// Single value screen. Communicates the one differentiator (beautiful, custom
/// QR codes), then drops the user straight into the app. Camera permission is
/// primed and the paywall is deferred to the first value moment — both handled
/// by `AppCoordinator.finishOnboarding()`.
struct OnboardingView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top brand bar
                HStack(spacing: 8) {
                    BrandMarkView(size: 24)
                    Text("QReative")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(-0.3)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Hero illustration
                HeroCreateView()
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.55).delay(0.05), value: showContent)

                Spacer().frame(height: 30)

                // Title
                Text("Make QR codes\nworth scanning")
                    .font(.system(size: 33, weight: .bold))
                    .tracking(-0.9)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.textPrimary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 14)
                    .animation(.easeOut(duration: 0.55).delay(0.14), value: showContent)

                // Body
                Text("Create and scan QR codes & barcodes — all in one place.")
                    .font(.system(size: 15.5))
                    .foregroundStyle(Color.ink2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 30)
                    .padding(.top, 14)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)
                    .animation(.easeOut(duration: 0.55).delay(0.20), value: showContent)

                // Capabilities (gives create + scan equal billing)
                VStack(spacing: 14) {
                    capabilityRow(
                        icon: "paintpalette.fill",
                        title: "Create",
                        subtitle: "Custom colors, shapes, logos & emojis"
                    )
                    capabilityRow(
                        icon: "viewfinder",
                        title: "Scan",
                        subtitle: "Read any QR code or barcode instantly"
                    )
                }
                .padding(.horizontal, 36)
                .padding(.top, 22)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
                .animation(.easeOut(duration: 0.55).delay(0.26), value: showContent)

                Spacer()

                // CTA button
                PrimaryButton(appLocalized("Get Started"), icon: "arrow.right") {
                    HapticManager.shared.mediumTap()
                    appCoordinator.completeOnboarding()
                }
                .padding(.horizontal, 30)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
                .animation(.easeOut(duration: 0.55).delay(0.32), value: showContent)
            }
            .padding(.bottom, 18)
        }
        .onAppear {
            AnalyticsService.onboardingStepViewed(step: 0, name: "value")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                withAnimation(.easeOut(duration: 0.45)) {
                    showContent = true
                }
            }
        }
    }

    // MARK: - Capability Row
    private func capabilityRow(
        icon: String,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey
    ) -> some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 11)
                .fill(Color.accentPrimary.opacity(0.12))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.accentPrimary)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.ink2)
            }

            Spacer()
        }
    }
}

// MARK: - Brand Mark
struct BrandMarkView: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "qrcode.viewfinder")
            .font(.system(size: size * 0.85, weight: .medium))
            .foregroundStyle(Color.textPrimary)
    }
}

// MARK: - Hero: Create
private struct HeroCreateView: View {
    var body: some View {
        ZStack {
            // Soft accent glow
            Circle()
                .fill(Color.accentPrimary.opacity(0.12))
                .frame(width: 210, height: 210)
                .blur(radius: 8)

            // Rotated QR card
            RoundedRectangle(cornerRadius: 26)
                .fill(Color.surface)
                .frame(width: 206, height: 206)
                .shadow(color: Color.ink.opacity(0.20), radius: 36, x: 0, y: 20)
                .rotationEffect(.degrees(-4))
                .overlay {
                    QRCodePreview(
                        content: "https://qreative.app/hello",
                        size: 170,
                        foregroundColor: .textPrimary,
                        backgroundColor: .white,
                        shape: .rounded,
                        logoImage: nil,
                        isGlowing: false
                    )
                    .rotationEffect(.degrees(-4))
                }

            // Style badge
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentPrimary)
                    .frame(width: 26, height: 26)
                    .overlay {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                Text("YOUR STYLE")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.ink2)
                    .tracking(0.5)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.lineColor, lineWidth: 1)
            }
            .shadow(color: Color.ink.opacity(0.08), radius: 8, x: 0, y: 4)
            .offset(x: 68, y: 88)
        }
        .frame(width: 250, height: 280)
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
        .environmentObject(AppCoordinator())
}
