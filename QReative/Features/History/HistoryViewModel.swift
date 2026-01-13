import SwiftUI
import Combine

// MARK: - History ViewModel
@MainActor
final class HistoryViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var items: [HistoryItem] = []
    @Published var isLoading: Bool = false
    @Published var selectedItem: HistoryItem?
    @Published var showDeleteConfirmation: Bool = false
    @Published var itemToDelete: HistoryItem?
    @Published var showShareSheet: Bool = false
    @Published var itemToShare: HistoryItem?
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Dependencies
    private let storageService: StorageService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Coordinators
    private weak var tabCoordinator: MainTabCoordinator?

    // MARK: - Computed Properties
    var isEmpty: Bool {
        items.isEmpty && !isLoading
    }

    var groupedItems: [String: [HistoryItem]] {
        Dictionary(grouping: items) { item in
            groupKey(for: item.createdAt)
        }
    }

    var sortedGroupKeys: [String] {
        let order = ["Today", "Yesterday", "This Week", "This Month", "Older"]
        return groupedItems.keys.sorted { key1, key2 in
            let index1 = order.firstIndex(of: key1) ?? order.count
            let index2 = order.firstIndex(of: key2) ?? order.count
            return index1 < index2
        }
    }

    // MARK: - Init
    init(storageService: StorageService? = nil) {
        self.storageService = storageService ?? StorageService.shared
        setupBindings()
    }

    // MARK: - Setup
    private func setupBindings() {
        storageService.$historyItems
            .receive(on: DispatchQueue.main)
            .assign(to: &$items)
    }

    func bind(tabCoordinator: MainTabCoordinator?) {
        self.tabCoordinator = tabCoordinator
    }

    // MARK: - Load History
    func loadHistory() async {
        isLoading = true

        _ = await storageService.loadHistory()

        isLoading = false
    }

    func refresh() async {
        await loadHistory()
    }

    // MARK: - Delete
    func confirmDelete(_ item: HistoryItem) {
        itemToDelete = item
        showDeleteConfirmation = true
    }

    func cancelDelete() {
        itemToDelete = nil
        showDeleteConfirmation = false
    }

    func deleteItem(_ item: HistoryItem) async {
        do {
            try await storageService.deleteItem(id: item.id)

            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        itemToDelete = nil
        showDeleteConfirmation = false
    }

    func deleteConfirmed() async {
        guard let item = itemToDelete else { return }
        await deleteItem(item)
    }

    // MARK: - Selection
    func selectItem(_ item: HistoryItem) {
        selectedItem = item

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        tabCoordinator?.pushToHistory(.qrDetail(historyItemId: item.id.uuidString))
    }

    // MARK: - Share
    func shareItem(_ item: HistoryItem) {
        itemToShare = item
        showShareSheet = true
    }

    func dismissShare() {
        itemToShare = nil
        showShareSheet = false
    }

    // MARK: - Copy
    func copyContent(_ item: HistoryItem) {
        UIPasteboard.general.string = item.content

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }

    // MARK: - Clear All
    func clearAllHistory() async {
        do {
            try await storageService.clearHistory()

            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Helpers
    private func groupKey(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return "This Week"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .month) {
            return "This Month"
        } else {
            return "Older"
        }
    }
}
