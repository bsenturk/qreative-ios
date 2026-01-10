//
//  QReativeApp.swift
//  QReative
//
//  Created by Burak Ahmet Şentürk on 10.01.2026.
//

import SwiftUI

@main
struct QReativeApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var tabCoordinator = MainTabCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appCoordinator)
                .environmentObject(tabCoordinator)
                .environment(\.appCoordinator, appCoordinator)
                .environment(\.tabCoordinator, tabCoordinator)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator

    var body: some View {
        Group {
            switch appCoordinator.currentRoute {
            case .onboarding:
                OnboardingView()
                    .transition(.opacity)

            case .paywall:
                PaywallView()
                    .transition(.opacity)

            case .mainTab:
                MainTabView()
                    .transition(.opacity)

            default:
                MainTabView()
            }
        }
        .animation(Theme.animation.easeInOut, value: appCoordinator.currentRoute)
        .onAppear {
            appCoordinator.start()
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var tabCoordinator: MainTabCoordinator

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            TabView(selection: $tabCoordinator.selectedTab) {
                NavigationStack(path: tabCoordinator.navigationPath(for: .scan)) {
                    ScanViewPlaceholder()
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                }
                .tag(Tab.scan)

                NavigationStack(path: tabCoordinator.navigationPath(for: .create)) {
                    CreateViewPlaceholder()
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                }
                .tag(Tab.create)

                NavigationStack(path: tabCoordinator.navigationPath(for: .history)) {
                    HistoryViewPlaceholder()
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                }
                .tag(Tab.history)

                NavigationStack(path: tabCoordinator.navigationPath(for: .settings)) {
                    SettingsViewPlaceholder()
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                }
                .tag(Tab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Tab Bar
            CustomTabBar(
                selectedTab: Binding(
                    get: { tabCoordinator.selectedTab },
                    set: { tabCoordinator.selectTab($0) }
                )
            )
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $appCoordinator.isPaywallPresented) {
            PaywallView()
        }
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .qrEditor(let qrTypeId):
            QREditorPlaceholder(qrTypeId: qrTypeId)
        case .qrDetail(let historyItemId):
            QRDetailPlaceholder(historyItemId: historyItemId)
        case .settings(let settingsRoute):
            SettingsDetailPlaceholder(route: settingsRoute)
        case .scanResult(let content):
            ScanResultPlaceholder(content: content)
        default:
            EmptyView()
        }
    }
}

// MARK: - Placeholder Views (to be replaced with actual views)

struct PaywallView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.goldGradient)

                Text("Unlock Premium")
                    .typography(.largeTitle)

                Text("Get access to all features")
                    .typography(.body, color: .textSecondary)

                Spacer()

                VStack(spacing: 12) {
                    PrimaryButton("Continue with Premium") {
                        appCoordinator.handlePurchaseSuccess()
                    }

                    PrimaryButton.secondary("Maybe Later") {
                        appCoordinator.dismissPaywall()
                    }
                }
                .padding(.horizontal, Theme.spacing.screen)
            }
            .padding(.bottom, 40)
        }
    }
}

struct ScanViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentPrimary)
                Text("Scan")
                    .typography(.title1)
            }
        }
    }
}

struct CreateViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentPrimary)
                Text("Create")
                    .typography(.title1)
            }
        }
    }
}

struct HistoryViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentPrimary)
                Text("History")
                    .typography(.title1)
            }
        }
    }
}

struct SettingsViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentPrimary)
                Text("Settings")
                    .typography(.title1)
            }
        }
    }
}

struct QREditorPlaceholder: View {
    let qrTypeId: String

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            Text("QR Editor: \(qrTypeId)")
                .typography(.title1)
        }
    }
}

struct QRDetailPlaceholder: View {
    let historyItemId: String

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            Text("QR Detail: \(historyItemId)")
                .typography(.title1)
        }
    }
}

struct SettingsDetailPlaceholder: View {
    let route: SettingsRoute

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            Text(route.title)
                .typography(.title1)
        }
    }
}

struct ScanResultPlaceholder: View {
    let content: String

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Scan Result")
                    .typography(.title1)
                Text(content)
                    .typography(.body, color: .textSecondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .environmentObject(AppCoordinator())
        .environmentObject(MainTabCoordinator())
}
