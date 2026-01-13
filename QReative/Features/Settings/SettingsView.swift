import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var tabCoordinator: MainTabCoordinator
    @StateObject private var viewModel = SettingsViewModel()
    @State private var bannerGlow = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.top, 60)
                    .padding(.bottom, 24)

                if !viewModel.isPremium {
                    proBanner
                        .padding(.bottom, 24)
                }

                ForEach(Array(viewModel.settingsGroups.enumerated()), id: \.offset) { index, group in
                    settingsGroup(group)
                        .padding(.bottom, 20)
                }

                footerSection
                    .padding(.top, 20)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, Theme.spacing.screen)
        }
        .background(Color.backgroundPrimary)
        .ignoresSafeArea()
        .onAppear {
            viewModel.bind(appCoordinator: appCoordinator, tabCoordinator: tabCoordinator)
            startBannerPulse()
        }
        .alert("Restore Purchases", isPresented: $viewModel.showRestoreAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.restoreMessage)
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheet(items: viewModel.shareItems)
        }
    }

    private func startBannerPulse() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(1)) {
            bannerGlow = true
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        Text("Settings")
            .typography(.largeTitle)
    }

    // MARK: - PRO Banner
    private var proBanner: some View {
        Button {
            HapticManager.shared.mediumTap()
            viewModel.showUpgrade()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient.goldGradient)
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.warning.opacity(bannerGlow ? 0.7 : 0.4), radius: bannerGlow ? 16 : 10, x: 0, y: 4)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Upgrade to PRO")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Unlock all premium features")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentPrimary.opacity(0.3),
                                Color.accentSecondary.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.accentPrimary.opacity(bannerGlow ? 0.7 : 0.4), lineWidth: bannerGlow ? 1.5 : 1)
            }
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }

    // MARK: - Settings Group
    private func settingsGroup(_ group: SettingsGroup) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(group.items.enumerated()), id: \.offset) { index, item in
                settingsRow(item)

                if index < group.items.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.06))
                        .padding(.leading, 52)
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    // MARK: - Settings Row
    private func settingsRow(_ item: SettingsItem) -> some View {
        Button {
            HapticManager.shared.lightTap()
            item.action()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(item.iconColor)
                }

                Text(item.title)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)

                Spacer()

                if let subtitle = item.subtitle {
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                        Text(subtitle)
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Color.warning)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(Color.warning.opacity(0.15))
                    }
                }

                if item.title == "Restore Purchases" && viewModel.isRestoring {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                }

                if item.showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .background(Color.white.opacity(0.001))
        }
        .buttonStyle(SettingsRowButtonStyle())
    }

    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("QReative")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))

            Text(viewModel.appVersion)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.3))

            Text("Made with ❤️")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.2))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - General Settings View (Placeholder)
struct GeneralSettingsView: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("General Settings")
                    .typography(.title1)

                Text("Coming soon...")
                    .typography(.body, color: .textSecondary)
            }
        }
        .navigationTitle("General")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - App Icon Settings View (Placeholder)
struct AppIconSettingsView: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("App Icon")
                    .typography(.title1)

                Text("Choose your app icon")
                    .typography(.body, color: .textSecondary)
            }
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Help & Support View (Placeholder)
struct HelpSupportView: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Help & Support")
                    .typography(.title1)

                Text("Contact us at support@qreative.app")
                    .typography(.body, color: .textSecondary)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Settings Row Button Style
private struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? Color.white.opacity(0.05) : Color.clear)
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(AppCoordinator())
        .environmentObject(MainTabCoordinator())
}
