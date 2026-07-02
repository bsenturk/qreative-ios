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

// MARK: - Storage Service
@MainActor
final class StorageService: ObservableObject {

    // MARK: - Singleton
    static let shared = StorageService()

    // MARK: - Published Properties
    @Published var historyItems: [HistoryItem] = []

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let historyKey = "qreative.history.items"
    private let maxHistoryItems = 100

    private let fileManager = FileManager.default
    /// Serial queue so disk writes happen off the main actor and in the same
    /// order as the in-memory mutations that scheduled them.
    private let diskQueue = DispatchQueue(label: "com.qreative.storage.disk", qos: .utility)
    /// Set once we have successfully loaded (or confirmed empty) from disk, so a
    /// later transient read failure can't wipe an already-loaded list.
    private var hasLoaded = false

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
        let isDuplicate = historyItems.contains { existing in
            existing.content == item.content &&
            abs(existing.createdAt.timeIntervalSince(item.createdAt)) < 60
        }

        guard !isDuplicate else { return }

        historyItems.insert(item, at: 0)

        if historyItems.count > maxHistoryItems {
            historyItems = Array(historyItems.prefix(maxHistoryItems))
        }

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

    // MARK: - Private - Disk Operations
    private func saveHistoryToDisk() async throws {
        // Snapshot on the main actor (in mutation order), then encode + write on
        // a serial background queue so we never block the UI and writes stay
        // ordered.
        let snapshot = historyItems
        let url = historyFileURL
        let key = historyKey
        let queue = diskQueue
        let defaults = userDefaults

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    let data = try encoder.encode(snapshot)
                    try data.write(to: url, options: .atomic)
                    defaults.set(data, forKey: key)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: StorageError.saveFailed(error))
                }
            }
        }
    }

    private func loadHistoryFromDisk() async {
        if let data = try? Data(contentsOf: historyFileURL) {
            if let items = decodeHistory(from: data) {
                historyItems = items
                hasLoaded = true
                return
            }
            // File exists but is unreadable/corrupt — preserve it for recovery
            // and DO NOT wipe whatever we already have in memory.
            backUpCorruptHistoryFile()
        }

        if let data = userDefaults.data(forKey: historyKey),
           let items = decodeHistory(from: data) {
            historyItems = items
            hasLoaded = true
            return
        }

        // Only initialize to empty on a genuine first launch (nothing decodable
        // anywhere and we've never loaded). Never clobber an already-loaded list
        // on a transient read failure.
        if !hasLoaded {
            historyItems = []
            hasLoaded = true
        }
    }

    /// Moves a corrupt history file aside (once) so a subsequent save doesn't
    /// overwrite recoverable data.
    private func backUpCorruptHistoryFile() {
        let url = historyFileURL
        let backup = url.deletingPathExtension().appendingPathExtension("corrupt.json")
        guard !fileManager.fileExists(atPath: backup.path) else { return }
        try? fileManager.moveItem(at: url, to: backup)
    }

    private func decodeHistory(from data: Data) -> [HistoryItem]? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([HistoryItem].self, from: data)
    }

}
