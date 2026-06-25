import SwiftUI

// MARK: - Create View
struct CreateView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var tabCoordinator: MainTabCoordinator
    @StateObject private var viewModel = CreateViewModel()
    @State private var showContent = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.top, 60)
                    .padding(.bottom, 18)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                qrTypeGrid

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 22)
        }
        .background(Color.backgroundPrimary)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            viewModel.bind(appCoordinator: appCoordinator, tabCoordinator: tabCoordinator)
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Create")
                .font(.system(size: 34, weight: .bold))
                .tracking(-1.0)
                .foregroundStyle(Color.textPrimary)

            Text("Choose a format to generate a QR code.")
                .font(.system(size: 15))
                .foregroundStyle(Color.ink2)
        }
    }

    // MARK: - QR Type Grid
    private var qrTypeGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(viewModel.primaryTemplates.enumerated()), id: \.element.id) { index, template in
                QRTypeGridItem(template: template, isPremiumUser: appCoordinator.isPremiumUser) {
                    viewModel.selectType(template)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.04 + 0.08), value: showContent)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CreateView()
        .environmentObject(AppCoordinator())
        .environmentObject(MainTabCoordinator())
}
