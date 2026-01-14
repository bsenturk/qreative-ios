import SwiftUI

// MARK: - Create View
struct CreateView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var tabCoordinator: MainTabCoordinator
    @StateObject private var viewModel = CreateViewModel()
    @State private var showContent = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.top, 60)
                    .padding(.bottom, 30)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                qrTypeGrid

                Spacer(minLength: 100)
            }
            .padding(.horizontal, Theme.spacing.screen)
        }
        .background(Color.backgroundPrimary)
        .ignoresSafeArea()
        .onAppear {
            viewModel.bind(appCoordinator: appCoordinator, tabCoordinator: tabCoordinator)
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }
        .sheet(isPresented: $viewModel.showMoreTypes) {
            MoreTypesSheet(
                templates: viewModel.additionalTemplates,
                isPremiumUser: appCoordinator.isPremiumUser,
                onSelect: { template in
                    viewModel.selectFromMoreOptions(template)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create")
                .typography(.largeTitle)

            Text("Choose a QR code type")
                .typography(.body, color: .textSecondary)
        }
    }

    // MARK: - QR Type Grid
    private var qrTypeGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(viewModel.primaryTemplates.enumerated()), id: \.element.id) { index, template in
                QRTypeGridItem(template: template, isPremiumUser: appCoordinator.isPremiumUser) {
                    viewModel.selectType(template)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05 + 0.1), value: showContent)
            }

            MoreGridItem {
                viewModel.showMoreOptions()
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(viewModel.primaryTemplates.count) * 0.05 + 0.1), value: showContent)
        }
    }
}

// MARK: - More Grid Item
private struct MoreGridItem: View {
    let onTap: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.lightTap()
            onTap()
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "4A4A4A"),
                                    Color(hex: "2C2C2E")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "ellipsis")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text("More")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            }
        }
        .buttonStyle(PressableStyle(scale: 0.97))
    }
}

// MARK: - More Types Sheet
private struct MoreTypesSheet: View {
    let templates: [QRTypeTemplate]
    let isPremiumUser: Bool
    let onSelect: (QRTypeTemplate) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 20)

            Text("More QR Types")
                .typography(.title2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.spacing.screen)
                .padding(.bottom, 20)

            VStack(spacing: 12) {
                ForEach(templates) { template in
                    QRTypeLargeCard(template: template, isPremiumUser: isPremiumUser) {
                        onSelect(template)
                    }
                }
            }
            .padding(.horizontal, Theme.spacing.screen)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }
}

// MARK: - Preview
#Preview {
    CreateView()
        .environmentObject(AppCoordinator())
        .environmentObject(MainTabCoordinator())
}
