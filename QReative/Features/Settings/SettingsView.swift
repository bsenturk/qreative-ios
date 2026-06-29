import SwiftUI
import MessageUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var tabCoordinator: MainTabCoordinator
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var settings = AppSettings.shared

    #if DEBUG
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showLanguagePicker = false
    #endif

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.top, 60)
                    .padding(.bottom, 24)

                if !appCoordinator.isPremiumUser {
                    proBanner
                        .padding(.bottom, 24)
                }

                accountSection
                    .padding(.bottom, 20)

                preferencesSection
                    .padding(.bottom, 20)

                scanningSection
                    .padding(.bottom, 20)

                ForEach(Array(viewModel.settingsGroups.enumerated()), id: \.offset) { index, group in
                    settingsGroup(group)
                        .padding(.bottom, 20)
                }

                #if DEBUG
                debugSection
                    .padding(.bottom, 20)
                #endif

                footerSection
                    .padding(.top, 20)

                Spacer(minLength: 24)
            }
            .padding(.horizontal, Theme.spacing.screen)
        }
        .background(Color.backgroundPrimary)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            AnalyticsService.logScreen("settings")
            viewModel.bind(appCoordinator: appCoordinator, tabCoordinator: tabCoordinator)
        }
        .alert("Restore Purchases", isPresented: $viewModel.showRestoreAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.restoreMessage)
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheet(items: viewModel.shareItems)
        }
        .sheet(isPresented: $viewModel.showMembershipSheet) {
            MembershipSheet(
                isPremium: appCoordinator.isPremiumUser,
                onManageSubscriptions: { viewModel.manageSubscriptions() },
                onRestore: { Task { await viewModel.restorePurchases() } },
                onGoPro: { viewModel.goProFromMembership() }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showMailComposer) {
            if MFMailComposeViewController.canSendMail() {
                MailComposeView(
                    recipient: "buraksenturktr@icloud.com",
                    subject: "QReative Support"
                )
            } else {
                MailUnavailableView(recipient: "buraksenturktr@icloud.com")
            }
        }
        #if DEBUG
        .sheet(isPresented: $showLanguagePicker) {
            DebugLanguagePickerView(languageManager: languageManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        #endif
    }

    #if DEBUG
    // MARK: - Debug Section (language testing — DEBUG builds only)
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DEBUG")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Color.ink3)
                .padding(.leading, 4)

            Button {
                HapticManager.shared.lightTap()
                showLanguagePicker = true
            } label: {
                HStack(spacing: 13) {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(hex: "AF52DE"))
                        .frame(width: 34, height: 34)
                        .overlay {
                            Image(systemName: "globe")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                        }

                    Text("Language")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    Text("\(languageManager.current.flag) \(languageManager.current.displayName)")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.ink3)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.ink3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(SettingsRowButtonStyle())
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.lineColor, lineWidth: 1)
            }
            .shadow(color: Color.ink.opacity(0.04), radius: 2, x: 0, y: 1)
            .shadow(color: Color.ink.opacity(0.06), radius: 12, x: 0, y: 6)
        }
    }
    #endif

    // MARK: - Header
    private var headerSection: some View {
        Text("Settings")
            .font(.system(size: 34, weight: .bold))
            .tracking(-1.0)
            .foregroundStyle(Color.textPrimary)
    }

    // MARK: - PRO Banner (non-premium)
    private var proBanner: some View {
        Button {
            HapticManager.shared.mediumTap()
            viewModel.showUpgrade()
        } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color.accentPrimary)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Upgrade to PRO")
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundStyle(Color.backgroundPrimary)
                    Text("Unlock all premium features")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.backgroundPrimary.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.backgroundPrimary.opacity(0.5))
            }
            .padding(16)
            .background(Color.ink)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.ink.opacity(0.20), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }

    // MARK: - Account Section (General + Membership Status)
    private var accountSection: some View {
        VStack(spacing: 0) {
            Button {
                viewModel.openGeneral()
            } label: {
                accountRowContent(
                    icon: "gearshape.fill",
                    title: "General"
                ) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.ink3)
                }
            }
            .buttonStyle(SettingsRowButtonStyle())

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.leading, 62)

            Button {
                viewModel.openMembership()
            } label: {
                accountRowContent(
                    icon: "person.crop.circle.fill",
                    title: "Membership Status"
                ) {
                    HStack(spacing: 6) {
                        Text(appCoordinator.isPremiumUser ? "Pro" : "Free")
                            .font(.system(size: 15, weight: appCoordinator.isPremiumUser ? .bold : .regular))
                            .foregroundStyle(appCoordinator.isPremiumUser ? Color.accentPrimary : Color.ink3)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.ink3)
                    }
                }
            }
            .buttonStyle(SettingsRowButtonStyle())
        }
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.lineColor, lineWidth: 1)
        }
        .shadow(color: Color.ink.opacity(0.04), radius: 2, x: 0, y: 1)
        .shadow(color: Color.ink.opacity(0.06), radius: 12, x: 0, y: 6)
    }

    @ViewBuilder
    private func accountRowContent<Trailing: View>(
        icon: String,
        title: LocalizedStringKey,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.surface2)
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                }

            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Preferences (toggles)
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Preferences")
            toggleCard {
                settingsToggleRow(
                    icon: "bolt.fill",
                    title: "Haptic feedback",
                    isOn: $settings.hapticFeedbackEnabled,
                    analyticsKey: "haptic_feedback",
                    isLast: true
                )
            }
        }
    }

    // MARK: - Scanning (toggles)
    private var scanningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Scanning")
            toggleCard {
                settingsToggleRow(
                    icon: "link",
                    title: "Auto-open links",
                    isOn: $settings.autoOpenLinks,
                    analyticsKey: "auto_open_links",
                    isLast: false
                )
                settingsToggleRow(
                    icon: "bell.fill",
                    title: "Scan sound",
                    isOn: $settings.scanSoundEnabled,
                    analyticsKey: "scan_sound",
                    isLast: true
                )
            }
        }
    }

    private func sectionLabel(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(Color.ink3)
            .padding(.leading, 4)
    }

    private func toggleCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.lineColor, lineWidth: 1)
            }
            .shadow(color: Color.ink.opacity(0.04), radius: 2, x: 0, y: 1)
            .shadow(color: Color.ink.opacity(0.06), radius: 12, x: 0, y: 6)
    }

    private func settingsToggleRow(
        icon: String,
        title: LocalizedStringKey,
        isOn: Binding<Bool>,
        analyticsKey: String,
        isLast: Bool
    ) -> some View {
        // Wrap the binding so flipping the toggle also logs the change.
        let trackedBinding = Binding<Bool>(
            get: { isOn.wrappedValue },
            set: { newValue in
                isOn.wrappedValue = newValue
                AnalyticsService.settingToggled(analyticsKey, enabled: newValue)
            }
        )
        return HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.surface2)
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                }

            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Toggle("", isOn: trackedBinding)
                .labelsHidden()
                .toggleStyle(SettingsToggleStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.lineColor)
                    .frame(height: 1)
                    .padding(.leading, 62)
            }
        }
    }

    // MARK: - Settings Group
    private func settingsGroup(_ group: SettingsGroup) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(group.items.enumerated()), id: \.offset) { index, item in
                settingsRow(item, isLast: index == group.items.count - 1)
            }
        }
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.lineColor, lineWidth: 1)
        }
        .shadow(color: Color.ink.opacity(0.04), radius: 2, x: 0, y: 1)
        .shadow(color: Color.ink.opacity(0.06), radius: 12, x: 0, y: 6)
    }

    // MARK: - Settings Row
    private func settingsRow(_ item: SettingsItem, isLast: Bool) -> some View {
        Button {
            HapticManager.shared.lightTap()
            item.action()
        } label: {
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.surface2)
                    .frame(width: 34, height: 34)
                    .overlay {
                        Image(systemName: item.icon)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                    }

                Text(item.title)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                if let subtitle = item.subtitle {
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                        Text(subtitle)
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Color.accentPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentPrimary.opacity(0.12))
                    .clipShape(Capsule())
                }

                if item.isRestore && viewModel.isRestoring {
                    ProgressView()
                        .tint(Color.ink2)
                        .scaleEffect(0.8)
                }

                if item.showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.ink3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if !isLast {
                    Rectangle()
                        .fill(Color.lineColor)
                        .frame(height: 1)
                        .padding(.leading, 62)
                }
            }
        }
        .buttonStyle(SettingsRowButtonStyle())
    }

    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 6) {
            Text("QReative")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.ink3)

            Text(viewModel.appVersion)
                .font(.system(size: 12))
                .foregroundStyle(Color.ink3.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Settings Toggle Style
/// Custom toggle style so the OFF state reads clearly against the white card surface.
/// SwiftUI's default off-track is a very light system gray that looks washed out here.
private struct SettingsToggleStyle: ToggleStyle {
    private let width: CGFloat = 51
    private let height: CGFloat = 31

    func makeBody(configuration: Configuration) -> some View {
        let isOn = configuration.isOn
        return Capsule()
            .fill(isOn ? Color.accentPrimary : Color.lineStrong)
            .frame(width: width, height: height)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .padding(2)
                    .shadow(color: Color.ink.opacity(0.18), radius: 1.5, x: 0, y: 1)
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isOn)
            .contentShape(Capsule())
            .onTapGesture {
                HapticManager.shared.lightTap()
                configuration.isOn.toggle()
            }
            .accessibilityRepresentation {
                Toggle(isOn: configuration.$isOn) { configuration.label }
            }
    }
}

// MARK: - Settings Row Button Style
private struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ? Color.surface2 : Color.clear
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Membership Sheet
struct MembershipSheet: View {
    let isPremium: Bool
    let onManageSubscriptions: () -> Void
    let onRestore: () -> Void
    let onGoPro: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    planHeaderCard
                    actionsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }

            if !isPremium {
                goProButton
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
            }
        }
        .background(Color.backgroundPrimary)
    }

    // MARK: - Plan Header
    private var planHeaderCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14)
                .fill(isPremium ? Color.accentPrimary.opacity(0.15) : Color.surface2)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: isPremium ? "crown.fill" : "person.crop.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isPremium ? Color.accentPrimary : Color.textPrimary)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(isPremium ? "Pro Plan" : "Free Plan")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(isPremium
                     ? "All features unlocked · Thank you!"
                     : "Ad-free experience and all features with Pro")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.lineColor, lineWidth: 1)
        }
    }

    // MARK: - Actions Card
    private var actionsCard: some View {
        VStack(spacing: 0) {
            actionRow(
                icon: "creditcard.fill",
                iconColor: Color(hex: "007AFF"),
                title: "Manage Subscriptions",
                showChevron: true
            ) {
                onManageSubscriptions()
            }

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.leading, 62)

            actionRow(
                icon: "arrow.clockwise",
                iconColor: Color(hex: "34C759"),
                title: "Restore Purchases",
                showChevron: false
            ) {
                onRestore()
            }
        }
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.lineColor, lineWidth: 1)
        }
    }

    private func actionRow(
        icon: String,
        iconColor: Color,
        title: LocalizedStringKey,
        showChevron: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 9)
                    .fill(iconColor)
                    .frame(width: 34, height: 34)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                    }

                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.ink3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(SettingsRowButtonStyle())
    }

    // MARK: - Go Pro Button
    private var goProButton: some View {
        Button {
            onGoPro()
        } label: {
            Text("Go Pro")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "3457C8"), Color(hex: "7048E8")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(hex: "3457C8").opacity(0.35), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }
}

// MARK: - Placeholder Views
struct GeneralSettingsView: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
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

struct AppIconSettingsView: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
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

struct HelpSupportView: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
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

#if DEBUG
// MARK: - Debug Language Picker (DEBUG builds only)
struct DebugLanguagePickerView: View {
    @ObservedObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { index, language in
                        Button {
                            HapticManager.shared.lightTap()
                            languageManager.current = language
                            dismiss()
                        } label: {
                            HStack(spacing: 13) {
                                Text(language.flag)
                                    .font(.system(size: 22))

                                Text(language.displayName)
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.textPrimary)

                                Spacer()

                                if languageManager.current == language {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Color.accentPrimary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 15)
                            .contentShape(Rectangle())
                            .overlay(alignment: .bottom) {
                                if index != AppLanguage.allCases.count - 1 {
                                    Rectangle()
                                        .fill(Color.lineColor)
                                        .frame(height: 1)
                                        .padding(.leading, 51)
                                }
                            }
                        }
                        .buttonStyle(SettingsRowButtonStyle())
                    }
                }
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.lineColor, lineWidth: 1)
                }
                .padding(.horizontal, Theme.spacing.screen)
                .padding(.top, 12)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
#endif

// MARK: - Preview
#if DEBUG
#Preview {
    SettingsView()
        .environmentObject(AppCoordinator())
        .environmentObject(MainTabCoordinator())
        .environmentObject(LanguageManager.shared)
}
#endif
