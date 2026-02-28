import Foundation

enum CheckDetector {
    static func kingSquare(for color: PieceColor, in state: GameState) -> Square? {
        state.board.pieces(for: color)
            .first(where: { $0.1.type == .king })?
            .0
    }

    static func isKingInCheck(color: PieceColor, in state: GameState) -> Bool {
        guard let kingSquare = kingSquare(for: color, in: state) else {
            return false
        }
        return isSquareAttacked(kingSquare, by: color.opposite, in: state)
    }

    static func isSquareAttacked(_ square: Square, by attacker: PieceColor, in state: GameState) -> Bool {
        if pawnAttackExists(on: square, by: attacker, in: state) {
            return true
        }

        if knightAttackExists(on: square, by: attacker, in: state) {
            return true
        }

        if slidingAttackExists(on: square, by: attacker, in: state, directions: [(1, 1), (-1, 1), (1, -1), (-1, -1)], validTypes: [.bishop, .queen]) {
            return true
        }

        if slidingAttackExists(on: square, by: attacker, in: state, directions: [(1, 0), (-1, 0), (0, 1), (0, -1)], validTypes: [.rook, .queen]) {
            return true
        }

        return kingAttackExists(on: square, by: attacker, in: state)
    }

    private static func pawnAttackExists(on square: Square, by attacker: PieceColor, in state: GameState) -> Bool {
        let rankOffset = attacker == .white ? -1 : 1
        for fileOffset in [-1, 1] {
            guard let candidate = Square(file: square.file + fileOffset, rank: square.rank + rankOffset),
                  let piece = state.board.piece(at: candidate) else {
                continue
            }
            if piece.color == attacker && piece.type == .pawn {
                return true
            }
        }
        return false
    }

    private static func knightAttackExists(on square: Square, by attacker: PieceColor, in state: GameState) -> Bool {
        let offsets = [
            (1, 2), (2, 1), (2, -1), (1, -2),
            (-1, -2), (-2, -1), (-2, 1), (-1, 2)
        ]

        for (fileOffset, rankOffset) in offsets {
            guard let candidate = Square(file: square.file + fileOffset, rank: square.rank + rankOffset),
                  let piece = state.board.piece(at: candidate) else {
                continue
            }
            if piece.color == attacker && piece.type == .knight {
                return true
            }
        }

        return false
    }

    private static func slidingAttackExists(
        on square: Square,
        by attacker: PieceColor,
        in state: GameState,
        directions: [(Int, Int)],
        validTypes: Set<PieceType>
    ) -> Bool {
        for (fileStep, rankStep) in directions {
            var file = square.file + fileStep
            var rank = square.rank + rankStep

            while let candidate = Square(file: file, rank: rank) {
                if let piece = state.board.piece(at: candidate) {
                    if piece.color == attacker && validTypes.contains(piece.type) {
                        return true
                    }
                    break
                }

                file += fileStep
                rank += rankStep
            }
        }

        return false
    }

    private static func kingAttackExists(on square: Square, by attacker: PieceColor, in state: GameState) -> Bool {
        for fileOffset in -1...1 {
            for rankOffset in -1...1 where !(fileOffset == 0 && rankOffset == 0) {
                guard let candidate = Square(file: square.file + fileOffset, rank: square.rank + rankOffset),
                      let piece = state.board.piece(at: candidate) else {
                    continue
                }
                if piece.color == attacker && piece.type == .king {
                    return true
                }
            }
        }
        return false
    }
}
