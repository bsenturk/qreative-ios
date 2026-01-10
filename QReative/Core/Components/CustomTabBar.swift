import SwiftUI

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    let onTabChange: ((Tab) -> Void)?

    init(selectedTab: Binding<Tab>, onTabChange: ((Tab) -> Void)? = nil) {
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
                ForEach(Tab.allCases, id: \.self) { tab in
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

    private func selectTab(_ tab: Tab) {
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
    let tab: Tab
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
    @Binding var selectedTab: Tab
    let content: (Tab) -> Content

    init(
        selectedTab: Binding<Tab>,
        @ViewBuilder content: @escaping (Tab) -> Content
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
    func withCustomTabBar(selectedTab: Binding<Tab>) -> some View {
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
        @State private var selectedTab: Tab = .scan

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
