import Foundation
import Observation

/// «آخر ما قرأت»: the last entries the reader opened, kept only on this phone (UserDefaults). No account, nothing sent anywhere.
@Observable
final class ReadingHistory {
    static let shared = ReadingHistory()

    struct Item: Codable, Identifiable, Hashable {
        let path: String
        let title: String
        let date: Date
        var id: String { path }
    }

    private(set) var items: [Item] = []
    private let key = "readingHistory.v1"
    private let limit = 20

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Item].self, from: data) {
            items = saved
        }
    }

    func record(path: String, title: String) {
        let clean = title.replacingOccurrences(of: "\u{200B}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        items.removeAll { $0.path == path }
        items.insert(Item(path: path, title: clean, date: .now), at: 0)
        if items.count > limit { items.removeLast(items.count - limit) }
        save()
    }

    func clear() {
        items = []
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) { UserDefaults.standard.set(data, forKey: key) }
    }
}
