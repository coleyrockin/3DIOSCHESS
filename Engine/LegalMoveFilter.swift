import Foundation

enum LegalMoveFilter {
    static func legalMoves(from square: Square, in state: GameState) -> [Move] {
        guard let piece = state.board.piece(at: square), piece.color == state.turn else {
            return []
        }

        return MoveGenerator.pseudoLegalMoves(from: square, in: state).filter { move in
            isMoveLegal(move, piece: piece, in: state)
        }
    }

    static func legalMoves(for color: PieceColor, in state: GameState) -> [Move] {
        state.board.pieces(for: color).flatMap { square, piece in
            MoveGenerator.pseudoLegalMoves(from: square, in: state).filter { move in
                isMoveLegal(move, piece: piece, in: state)
            }
        }
    }

    private static func isMoveLegal(_ move: Move, piece: Piece, in state: GameState) -> Bool {
        if move.isCastling && !castlingPathIsSafe(move, kingColor: piece.color, in: state) {
            return false
        }

        var simulated = state
        Rules.applyUnchecked(move, in: &simulated)
        return !CheckDetector.isKingInCheck(color: piece.color, in: simulated)
    }

    private static func castlingPathIsSafe(_ move: Move, kingColor: PieceColor, in state: GameState) -> Bool {
        guard !CheckDetector.isKingInCheck(color: kingColor, in: state) else {
            return false
        }

        let homeRank = kingColor == .white ? 0 : 7
        guard move.from == Square(file: 4, rank: homeRank)! else {
            return false
        }

        let throughFile = move.to.file == 6 ? 5 : 3
        guard let throughSquare = Square(file: throughFile, rank: homeRank) else {
            return false
        }

        if CheckDetector.isSquareAttacked(throughSquare, by: kingColor.opposite, in: state) {
            return false
        }

        return !CheckDetector.isSquareAttacked(move.to, by: kingColor.opposite, in: state)
    }
}
