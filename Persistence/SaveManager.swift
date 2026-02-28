import Foundation

enum SaveManagerError: Error {
    case documentsDirectoryUnavailable
}

struct SavedGame: Codable {
    let state: GameState
    let history: [GameState]
    let mode: GameMode
    let savedAt: Date
}

final class SaveManager {
    static let shared = SaveManager()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private func saveURL() throws -> URL {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw SaveManagerError.documentsDirectoryUnavailable
        }
        return documents.appendingPathComponent("chess3d_save.json")
    }

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func save(state: GameState, history: [GameState], mode: GameMode) throws {
        let payload = SavedGame(state: state, history: history, mode: mode, savedAt: Date())
        let data = try encoder.encode(payload)
        try data.write(to: saveURL(), options: .atomic)
    }

    func load() throws -> SavedGame {
        let data = try Data(contentsOf: saveURL())
        return try decoder.decode(SavedGame.self, from: data)
    }

    func hasSave() -> Bool {
        (try? saveURL()).map { FileManager.default.fileExists(atPath: $0.path) } ?? false
    }

    func deleteSave() {
        try? FileManager.default.removeItem(at: saveURL())
    }
}
