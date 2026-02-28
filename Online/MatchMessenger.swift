import Foundation

struct OnlineMoveMessage: Codable {
    let fromFile: Int
    let fromRank: Int
    let toFile: Int
    let toRank: Int
    let promotion: PieceType?
    let isEnPassant: Bool
    let isCastling: Bool
}

enum MatchMessengerError: Error {
    case invalidSquare
}

final class MatchMessenger {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func encode(move: Move) throws -> Data {
        let message = OnlineMoveMessage(
            fromFile: move.from.file,
            fromRank: move.from.rank,
            toFile: move.to.file,
            toRank: move.to.rank,
            promotion: move.promotion,
            isEnPassant: move.isEnPassant,
            isCastling: move.isCastling
        )
        return try encoder.encode(message)
    }

    func decodeMove(from data: Data) throws -> Move {
        let payload = try decoder.decode(OnlineMoveMessage.self, from: data)
        guard let from = Square(file: payload.fromFile, rank: payload.fromRank),
              let to = Square(file: payload.toFile, rank: payload.toRank) else {
            throw MatchMessengerError.invalidSquare
        }

        return Move(from: from, to: to, promotion: payload.promotion,
                    isEnPassant: payload.isEnPassant, isCastling: payload.isCastling)
    }
}
