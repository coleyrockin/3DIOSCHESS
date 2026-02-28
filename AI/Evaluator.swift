import Foundation

enum Evaluator {
    private static let materialValues: [PieceType: Int] = [
        .pawn: 100,
        .knight: 320,
        .bishop: 330,
        .rook: 500,
        .queen: 900,
        .king: 20_000
    ]

    static func evaluate(_ state: GameState, perspective: PieceColor) -> Int {
        switch state.status {
        case .checkmate:
            if state.winner == perspective {
                return 100_000
            }
            return -100_000
        case .stalemate:
            return 0
        case .check, .ongoing:
            break
        }

        let whiteMaterial = materialScore(for: .white, in: state)
        let blackMaterial = materialScore(for: .black, in: state)
        let mobility = Rules.allLegalMoves(in: state).count

        let signedMaterial = perspective == .white ? (whiteMaterial - blackMaterial) : (blackMaterial - whiteMaterial)
        let signedMobility = (state.turn == perspective ? 1 : -1) * mobility

        return signedMaterial + signedMobility
    }

    private static func materialScore(for color: PieceColor, in state: GameState) -> Int {
        state.board.pieces(for: color).reduce(0) { partial, item in
            partial + (materialValues[item.1.type] ?? 0)
        }
    }
}
