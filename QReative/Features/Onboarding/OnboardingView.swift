import SwiftUI

// MARK: - Onboarding Page Data
private struct OnboardingPageContent {
    let name: String
    let title: String
    let body: String
}

private let pages: [OnboardingPageContent] = [
    OnboardingPageContent(
        name: "create",
        title: "Make QR codes\nworth scanning",
        body: "Custom colors, shapes, logos, and emojis — beautiful by default."
    ),
    OnboardingPageContent(
        name: "scan",
        title: "Scan anything,\ninstantly",
        body: "Point at any QR code or barcode — fast, accurate, effortless."
    ),
    OnboardingPageContent(
        name: "history",
        title: "Your codes,\nalways with you",
        body: "Every scan and creation — saved, searchable, ready to revisit."
    ),
]

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var currentPage: Int = 0
    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top brand bar
                HStack {
                    HStack(spacing: 8) {
                        BrandMarkView(size: 24)
                        Text("QReative")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(-0.3)
                            .foregroundStyle(Color.textPrimary)
                    }
                    Spacer()
                    Button {
                        appCoordinator.skipOnboarding(atStep: currentPage)
                    } label: {
                        Text("Skip")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.ink3)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageContent(for: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, newPage in
                    HapticManager.shared.lightTap()
                    AnalyticsService.onboardingStepViewed(step: newPage, name: pages[newPage].name)
                    withAnimation(.easeOut(duration: 0.3)) {
                        showContent = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                        withAnimation(.easeOut(duration: 0.45)) {
                            showContent = true
                        }
                    }
                }

                // Page dots
                PageDotsView(count: pages.count, active: currentPage)
                    .padding(.bottom, 26)
                    .opacity(showContent ? 1 : 0)

                // CTA button
                PrimaryButton(
                    currentPage == pages.count - 1 ? "Get Started" : "Continue",
                    icon: "arrow.right"
                ) {
                    HapticManager.shared.mediumTap()
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        appCoordinator.completeOnboarding()
                    }
                }
                .padding(.horizontal, 30)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
            }
            .padding(.bottom, 18)
        }
        .onAppear {
            AnalyticsService.onboardingStepViewed(step: 0, name: pages[0].name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                withAnimation(.easeOut(duration: 0.45)) {
                    showContent = true
                }
            }
        }
    }

    // MARK: - Page Content
    private func pageContent(for index: Int) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero illustration
            Group {
                switch index {
                case 0:  HeroCreateView()
                case 1:  HeroScanView()
                default: HeroHistoryView()
                }
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeOut(duration: 0.55).delay(0.05), value: showContent)

            Spacer().frame(height: 30)

            // Title
            Text(pages[index].title)
                .font(.system(size: 33, weight: .bold))
                .tracking(-0.9)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.textPrimary)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 14)
                .animation(.easeOut(duration: 0.55).delay(0.14), value: showContent)

            // Body
            Text(pages[index].body)
                .font(.system(size: 15.5))
                .foregroundStyle(Color.ink2)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 30)
                .padding(.top, 16)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
                .animation(.easeOut(duration: 0.55).delay(0.20), value: showContent)

            Spacer()
        }
    }
}

// MARK: - Page Dots
private struct PageDotsView: View {
    let count: Int
    let active: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == active ? Color.accentPrimary : Color.lineStrong)
                    .frame(width: i == active ? 22 : 6, height: 6)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: active)
            }
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

// MARK: - Hero: Scan
private struct HeroScanView: View {
    @State private var scanOffset: CGFloat = 6

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.surface2)
                .frame(width: 230, height: 230)
                .overlay {
                    // Diagonal stripe pattern
                    Canvas { context, size in
                        let spacing: CGFloat = 9
                        var x: CGFloat = -size.height
                        while x < size.width + size.height {
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                            context.stroke(path, with: .color(Color.lineStrong.opacity(0.5)), lineWidth: 1)
                            x += spacing
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .overlay {
                    // Center QR card
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.surface)
                        .frame(width: 128, height: 128)
                        .overlay {
                            QRCodePreview(
                                content: "scan me",
                                size: 104,
                                foregroundColor: .textPrimary,
                                backgroundColor: .white,
                                shape: .rounded,
                                logoImage: nil,
                                isGlowing: false
                            )
                        }
                        .shadow(color: Color.ink.opacity(0.10), radius: 12, x: 0, y: 4)
                }
                .overlay {
                    // Viewfinder corners
                    ViewfinderCornersView(size: 230, color: Color.textPrimary, inset: 20)
                }
                .overlay {
                    // Scan line
                    Color.accentPrimary
                        .frame(height: 2)
                        .frame(width: 230 - 52)
                        .cornerRadius(1)
                        .shadow(color: Color.accentPrimary, radius: 8)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.top, 6)
                        .offset(y: scanOffset)
                        .animation(.linear(duration: 2.6).repeatForever(autoreverses: false), value: scanOffset)
                }
        }
        .frame(width: 250, height: 280)
        .onAppear {
            scanOffset = 224
        }
    }
}

// MARK: - Hero: History
private struct HeroHistoryView: View {
    private let items = [
        (icon: "globe", title: "qreative.app", sub: "Website · Today"),
        (icon: "wifi", title: "Studio_5G", sub: "WiFi · Yesterday"),
        (icon: "person.crop.rectangle", title: "Mara Lindqvist", sub: "Contact · Mon"),
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surface2)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: item.icon)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(Color.textPrimary)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 14.5, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                        Text(item.sub)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Color.ink3)
                    }

                    Spacer()

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.surface2)
                        .frame(width: 30, height: 30)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.lineColor, lineWidth: 1)
                }
                .shadow(color: Color.ink.opacity(0.04), radius: 2, x: 0, y: 1)
                .shadow(color: Color.ink.opacity(0.08), radius: 10, x: 0, y: 4)
                .offset(x: index == 1 ? 14 : 0)
            }
        }
        .frame(width: 256, height: 280)
        .padding(.vertical, 16)
    }
}

// MARK: - Viewfinder Corners
struct ViewfinderCornersView: View {
    let size: CGFloat
    let color: Color
    let inset: CGFloat

    var body: some View {
        let L: CGFloat = 30
        let sw: CGFloat = 3
        let off = inset

        Canvas { context, _ in
            let corners: [(CGFloat, CGFloat, Bool, Bool)] = [
                (off, off, false, false),
                (size - off, off, true, false),
                (off, size - off, false, true),
                (size - off, size - off, true, true),
            ]

            for (x, y, flipH, flipV) in corners {
                let hDir: CGFloat = flipH ? -1 : 1
                let vDir: CGFloat = flipV ? -1 : 1

                var p = Path()
                p.move(to: CGPoint(x: x + hDir * L, y: y))
                p.addLine(to: CGPoint(x: x, y: y))
                p.addLine(to: CGPoint(x: x, y: y + vDir * L))
                context.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: sw, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
        .environmentObject(AppCoordinator())
}
