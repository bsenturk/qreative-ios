import SwiftUI
import Combine

// MARK: - Storage Error

enum StorageError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case itemNotFound
    case saveFailed(Error)
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .itemNotFound:
            return "Item not found"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete: \(error.localizedDescription)"
        }
    }
}

// MARK: - Storage Service Protocol

protocol StorageServiceProtocol {
    var historyItems: [HistoryItem] { get }
    var historyItemsPublisher: Published<[HistoryItem]>.Publisher { get }

    func saveItem(_ item: HistoryItem) async throws
    func loadHistory() async -> [HistoryItem]
    func deleteItem(id: UUID) async throws
    func clearHistory() async throws
    func updateItem(_ item: HistoryItem) async throws
}

// MARK: - Storage Service

@MainActor
final class StorageService: ObservableObject, StorageServiceProtocol {

    // MARK: - Singleton

    static let shared = StorageService()

    // MARK: - Published Properties

    @Published var historyItems: [HistoryItem] = []

    var historyItemsPublisher: Published<[HistoryItem]>.Publisher {
        $historyItems
    }

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let historyKey = "qreative.history.items"
    private let maxHistoryItems = 100

    private let fileManager = FileManager.default
    private var historyFileURL: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("qreative_history.json")
    }

    // MARK: - Init

    init() {
        Task {
            await loadHistoryFromDisk()
        }
    }

    // MARK: - Save Item

    func saveItem(_ item: HistoryItem) async throws {
        // Check for duplicates (same content within last minute)
        let isDuplicate = historyItems.contains { existing in
            existing.content == item.content &&
            abs(existing.createdAt.timeIntervalSince(item.createdAt)) < 60
        }

        guard !isDuplicate else { return }

        // Add to beginning of array
        historyItems.insert(item, at: 0)

        // Trim if exceeds max
        if historyItems.count > maxHistoryItems {
            historyItems = Array(historyItems.prefix(maxHistoryItems))
        }

        // Persist
        try await saveHistoryToDisk()
    }

    // MARK: - Load History

    func loadHistory() async -> [HistoryItem] {
        await loadHistoryFromDisk()
        return historyItems
    }

    // MARK: - Delete Item

    func deleteItem(id: UUID) async throws {
        guard let index = historyItems.firstIndex(where: { $0.id == id }) else {
            throw StorageError.itemNotFound
        }

        historyItems.remove(at: index)

        try await saveHistoryToDisk()
    }

    // MARK: - Delete Multiple Items

    func deleteItems(ids: Set<UUID>) async throws {
        historyItems.removeAll { ids.contains($0.id) }
        try await saveHistoryToDisk()
    }

    // MARK: - Clear History

    func clearHistory() async throws {
        historyItems.removeAll()
        try await saveHistoryToDisk()
    }

    // MARK: - Update Item

    func updateItem(_ item: HistoryItem) async throws {
        guard let index = historyItems.firstIndex(where: { $0.id == item.id }) else {
            throw StorageError.itemNotFound
        }

        historyItems[index] = item

        try await saveHistoryToDisk()
    }

    // MARK: - Search

    func searchHistory(query: String) -> [HistoryItem] {
        guard !query.isEmpty else { return historyItems }

        let lowercasedQuery = query.lowercased()

        return historyItems.filter { item in
            item.content.lowercased().contains(lowercasedQuery) ||
            item.displayTitle.lowercased().contains(lowercasedQuery) ||
            item.type.title.lowercased().contains(lowercasedQuery)
        }
    }

    // MARK: - Filter by Type

    func filterHistory(by type: HistoryItemType) -> [HistoryItem] {
        historyItems.filter { $0.type == type }
    }

    // MARK: - Recent Items

    func recentItems(limit: Int = 5) -> [HistoryItem] {
        Array(historyItems.prefix(limit))
    }

    // MARK: - Private - Disk Operations

    private func saveHistoryToDisk() async throws {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(historyItems)

            // Save to file
            try data.write(to: historyFileURL, options: .atomic)

            // Also save to UserDefaults as backup
            userDefaults.set(data, forKey: historyKey)

        } catch {
            throw StorageError.saveFailed(error)
        }
    }

    private func loadHistoryFromDisk() async {
        // Try loading from file first
        if let data = try? Data(contentsOf: historyFileURL) {
            if let items = decodeHistory(from: data) {
                historyItems = items
                return
            }
        }

        // Fallback to UserDefaults
        if let data = userDefaults.data(forKey: historyKey) {
            if let items = decodeHistory(from: data) {
                historyItems = items
                return
            }
        }

        // No history found
        historyItems = []
    }

    private func decodeHistory(from data: Data) -> [HistoryItem]? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([HistoryItem].self, from: data)
    }

    // MARK: - Thumbnail Management

    func saveThumbnail(for itemId: UUID, imageData: Data) async throws {
        guard var item = historyItems.first(where: { $0.id == itemId }) else {
            throw StorageError.itemNotFound
        }

        item.thumbnailData = imageData
        try await updateItem(item)
    }

    // MARK: - Export

    func exportHistory() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(historyItems)
    }

    // MARK: - Import

    func importHistory(from data: Data) async throws {
        guard let items = decodeHistory(from: data) else {
            throw StorageError.decodingFailed
        }

        // Merge with existing, avoiding duplicates
        for item in items {
            if !historyItems.contains(where: { $0.id == item.id }) {
                historyItems.append(item)
            }
        }

        // Sort by date
        historyItems.sort { $0.createdAt > $1.createdAt }

        // Trim if needed
        if historyItems.count > maxHistoryItems {
            historyItems = Array(historyItems.prefix(maxHistoryItems))
        }

        try await saveHistoryToDisk()
    }

    // MARK: - Statistics

    var totalScans: Int {
        historyItems.count
    }

    var scansToday: Int {
        let calendar = Calendar.current
        return historyItems.filter { calendar.isDateInToday($0.createdAt) }.count
    }

    var mostUsedType: HistoryItemType? {
        let grouped = Dictionary(grouping: historyItems, by: { $0.type })
        return grouped.max(by: { $0.value.count < $1.value.count })?.key
    }
}

// MARK: - Environment Key

private struct StorageServiceKey: EnvironmentKey {
    static let defaultValue = StorageService.shared
}

extension EnvironmentValues {
    var storageService: StorageService {
        get { self[StorageServiceKey.self] }
        set { self[StorageServiceKey.self] = newValue }
    }
}
