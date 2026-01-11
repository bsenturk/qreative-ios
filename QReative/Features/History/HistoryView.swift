import SwiftUI

// MARK: - History View

struct HistoryView: View {
    @EnvironmentObject var tabCoordinator: MainTabCoordinator
    @StateObject private var viewModel = HistoryViewModel()
    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            if viewModel.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .onAppear {
            viewModel.bind(tabCoordinator: tabCoordinator)
            Task {
                await viewModel.loadHistory()
            }
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .confirmationDialog(
            "Delete QR Code",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteConfirmed()
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelDelete()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let item = viewModel.itemToShare {
                ShareSheet(items: [item.content])
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(Color.accentPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showContent ? 1 : 0.5)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentPrimary.opacity(0.5))
                    .scaleEffect(showContent ? 1 : 0)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showContent)

            VStack(spacing: 8) {
                Text("No QR codes yet")
                    .typography(.title2)

                Text("Your scanned and created codes will appear here")
                    .typography(.body, color: .textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)

            Spacer()
        }
        .padding(.bottom, 100)
    }

    // MARK: - History List

    private var historyList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 60)
                    .padding(.bottom, 24)
                    .padding(.horizontal, Theme.spacing.screen)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // Items
                LazyVStack(spacing: 12) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        HistoryRowView(
                            item: item,
                            onTap: { viewModel.selectItem(item) },
                            onDelete: {
                                HapticManager.shared.warning()
                                viewModel.confirmDelete(item)
                            },
                            onShare: { viewModel.shareItem(item) }
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : 50)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(min(index, 10)) * 0.05 + 0.15), value: showContent)
                    }
                }
                .padding(.horizontal, Theme.spacing.screen)

                Spacer(minLength: 100)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Text("History")
                .typography(.largeTitle)

            Spacer()

            if !viewModel.items.isEmpty {
                Menu {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.clearAllHistory()
                        }
                    } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Grouped History View (Alternative)

struct GroupedHistoryView: View {
    @EnvironmentObject var tabCoordinator: MainTabCoordinator
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            if viewModel.isEmpty {
                emptyState
            } else {
                groupedHistoryList
            }
        }
        .onAppear {
            viewModel.bind(tabCoordinator: tabCoordinator)
            Task {
                await viewModel.loadHistory()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(Color.textTertiary)

            Text("No history yet")
                .typography(.title2, color: .textSecondary)

            Spacer()
        }
    }

    private var groupedHistoryList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("History")
                    .typography(.largeTitle)
                    .padding(.top, 60)
                    .padding(.horizontal, Theme.spacing.screen)

                // Grouped sections
                ForEach(viewModel.sortedGroupKeys, id: \.self) { key in
                    if let items = viewModel.groupedItems[key] {
                        VStack(alignment: .leading, spacing: 12) {
                            // Section header
                            Text(key)
                                .typography(.caption1, color: .textTertiary)
                                .padding(.horizontal, Theme.spacing.screen)

                            // Items
                            VStack(spacing: 8) {
                                ForEach(items) { item in
                                    HistoryRowView(
                                        item: item,
                                        onTap: { viewModel.selectItem(item) },
                                        onDelete: { viewModel.confirmDelete(item) },
                                        onShare: { viewModel.shareItem(item) }
                                    )
                                }
                            }
                            .padding(.horizontal, Theme.spacing.screen)
                        }
                    }
                }

                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - Preview

#Preview("History View") {
    HistoryView()
        .environmentObject(MainTabCoordinator())
}

#Preview("Empty State") {
    HistoryView()
        .environmentObject(MainTabCoordinator())
}
