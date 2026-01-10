import SwiftUI

// MARK: - Tab Item

enum TabItem: Int, CaseIterable {
    case scan
    case create
    case history
    case settings

    var title: String {
        switch self {
        case .scan: return "Scan"
        case .create: return "Create"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .scan: return "viewfinder"
        case .create: return "qrcode.viewfinder"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        }
    }

    var selectedIcon: String {
        switch self {
        case .scan: return "viewfinder"
        case .create: return "qrcode.viewfinder"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    let onTabChange: ((TabItem) -> Void)?

    init(selectedTab: Binding<TabItem>, onTabChange: ((TabItem) -> Void)? = nil) {
        self._selectedTab = selectedTab
        self.onTabChange = onTabChange
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            // Tab items
            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    TabItemView(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        selectTab(tab)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 4)
        }
        .frame(height: 84)
        .background {
            Rectangle()
                .fill(Color(hex: "1C1C1E").opacity(0.95))
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Tab Selection

    private func selectTab(_ tab: TabItem) {
        guard selectedTab != tab else { return }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Animate selection
        withAnimation(Theme.animation.spring) {
            selectedTab = tab
        }

        // Callback
        onTabChange?(tab)
    }
}

// MARK: - Tab Item View

private struct TabItemView: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22, weight: .medium))
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color.accentPrimary : Color.white.opacity(0.4))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Bar Container

struct TabBarContainer<Content: View>: View {
    @Binding var selectedTab: TabItem
    let content: (TabItem) -> Content

    init(
        selectedTab: Binding<TabItem>,
        @ViewBuilder content: @escaping (TabItem) -> Content
    ) {
        self._selectedTab = selectedTab
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            content(selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 84)

            // Tab bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - View Extension

extension View {
    func withCustomTabBar(selectedTab: Binding<TabItem>) -> some View {
        ZStack(alignment: .bottom) {
            self
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 84)

            CustomTabBar(selectedTab: selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTab: TabItem = .scan

        var body: some View {
            TabBarContainer(selectedTab: $selectedTab) { tab in
                ZStack {
                    Color.backgroundPrimary
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        Image(systemName: tab.selectedIcon)
                            .font(.system(size: 48))
                            .foregroundStyle(Color.accentPrimary)

                        Text(tab.title)
                            .typography(.title1)
                    }
                }
            }
        }
    }

    return PreviewWrapper()
}
