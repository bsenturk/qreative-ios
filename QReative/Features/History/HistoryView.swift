import SwiftUI

// MARK: - History Filter
enum HistoryFilter: String, CaseIterable {
    case all = "All"
    case scanned = "Scanned"
    case created = "Created"
}

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject var tabCoordinator: MainTabCoordinator
    @StateObject private var viewModel = HistoryViewModel()
    @State private var showContent = false
    @State private var filter: HistoryFilter = .all

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            if viewModel.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .onAppear {
            viewModel.bind(tabCoordinator: tabCoordinator)
            Task { await viewModel.loadHistory() }
            withAnimation(.easeOut(duration: 0.4)) { showContent = true }
        }
        .refreshable { await viewModel.refresh() }
        .confirmationDialog(
            "Delete QR Code",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteConfirmed() }
            }
            Button("Cancel", role: .cancel) { viewModel.cancelDelete() }
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

            ZStack {
                Circle()
                    .fill(Color.surface2)
                    .frame(width: 96, height: 96)
                    .scaleEffect(showContent ? 1 : 0.5)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.ink3)
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
                HStack(alignment: .center) {
                    Text("History")
                        .font(.system(size: 34, weight: .bold))
                        .tracking(-1.0)
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    if !viewModel.items.isEmpty {
                        Menu {
                            Button(role: .destructive) {
                                Task { await viewModel.clearAllHistory() }
                            } label: {
                                Label("Clear All", systemImage: "trash")
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(Color.surface)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 13)
                                            .stroke(Color.lineColor, lineWidth: 1)
                                    }
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(Color.textPrimary)
                            }
                        }
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 16)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Filter tabs
                filterTabs
                    .padding(.bottom, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 12)
                    .animation(.easeOut(duration: 0.4).delay(0.05), value: showContent)

                // Grouped items
                ForEach(Array(viewModel.sortedGroupKeys.enumerated()), id: \.element) { gi, key in
                    if let items = viewModel.groupedItems[key] {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(key.uppercased())
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .tracking(0.5)
                                .foregroundStyle(Color.ink3)
                                .padding(.bottom, -2)

                            VStack(spacing: 0) {
                                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                    HistoryRowView(
                                        item: item,
                                        isLast: index == items.count - 1,
                                        onTap: { viewModel.selectItem(item) },
                                        onDelete: {
                                            HapticManager.shared.warning()
                                            viewModel.confirmDelete(item)
                                        },
                                        onShare: { viewModel.shareItem(item) }
                                    )
                                }
                            }
                            .background(Color.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.lineColor, lineWidth: 1)
                            }
                            .shadow(color: Color.ink.opacity(0.04), radius: 2, x: 0, y: 1)
                            .shadow(color: Color.ink.opacity(0.08), radius: 14, x: 0, y: 6)
                        }
                        .padding(.bottom, 18)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(gi) * 0.05 + 0.15), value: showContent)
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 22)
        }
    }

    // MARK: - Filter Tabs
    private var filterTabs: some View {
        HStack(spacing: 4) {
            ForEach(HistoryFilter.allCases, id: \.self) { f in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        filter = f
                    }
                } label: {
                    Text(f.rawValue)
                        .font(.system(size: 13.5, weight: .semibold))
                        .tracking(-0.1)
                        .foregroundStyle(filter == f ? Color.textPrimary : Color.ink3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            filter == f
                                ? Color.surface
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(
                            color: filter == f ? Color.ink.opacity(0.10) : .clear,
                            radius: 3, x: 0, y: 1
                        )
                }
            }
        }
        .padding(4)
        .background(Color.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.lineColor, lineWidth: 1)
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
        HistoryView()
            .environmentObject(tabCoordinator)
    }
}

// MARK: - Preview
#Preview("History View") {
    HistoryView()
        .environmentObject(MainTabCoordinator())
}
