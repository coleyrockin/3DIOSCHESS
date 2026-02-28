import Foundation

enum MoveGenerator {
    static func pseudoLegalMoves(from square: Square, in state: GameState) -> [Move] {
        guard let piece = state.board.piece(at: square) else {
            return []
        }

        switch piece.type {
        case .pawn:
            return pawnMoves(from: square, piece: piece, in: state)
        case .knight:
            return knightMoves(from: square, piece: piece, in: state)
        case .bishop:
            return slidingMoves(from: square, piece: piece, in: state, directions: [(1, 1), (-1, 1), (1, -1), (-1, -1)])
        case .rook:
            return slidingMoves(from: square, piece: piece, in: state, directions: [(1, 0), (-1, 0), (0, 1), (0, -1)])
        case .queen:
            return slidingMoves(
                from: square,
                piece: piece,
                in: state,
                directions: [(1, 1), (-1, 1), (1, -1), (-1, -1), (1, 0), (-1, 0), (0, 1), (0, -1)]
            )
        case .king:
            return kingMoves(from: square, piece: piece, in: state)
        }
    }

    static func pseudoLegalMoves(for color: PieceColor, in state: GameState) -> [Move] {
        state.board.pieces(for: color).flatMap { square, _ in
            pseudoLegalMoves(from: square, in: state)
        }
    }

    private static func pawnMoves(from square: Square, piece: Piece, in state: GameState) -> [Move] {
        var moves: [Move] = []

        let direction = piece.color == .white ? 1 : -1
        let startRank = piece.color == .white ? 1 : 6
        let promotionRank = piece.color == .white ? 7 : 0

        if let oneStep = Square(file: square.file, rank: square.rank + direction),
           state.board.piece(at: oneStep) == nil {
            moves.append(contentsOf: withPromotionIfNeeded(from: square, to: oneStep, promotionRank: promotionRank))

            if square.rank == startRank,
               let twoStep = Square(file: square.file, rank: square.rank + (2 * direction)),
               state.board.piece(at: twoStep) == nil {
                moves.append(Move(from: square, to: twoStep))
            }
        }

        for fileOffset in [-1, 1] {
            guard let captureSquare = Square(file: square.file + fileOffset, rank: square.rank + direction) else {
                continue
            }

            if let targetPiece = state.board.piece(at: captureSquare), targetPiece.color != piece.color {
                moves.append(contentsOf: withPromotionIfNeeded(from: square, to: captureSquare, promotionRank: promotionRank))
            }

            if let enPassantTarget = state.enPassantTarget, enPassantTarget == captureSquare {
                moves.append(Move(from: square, to: captureSquare, isEnPassant: true))
            }
        }

        return moves
    }

    private static func withPromotionIfNeeded(from: Square, to: Square, promotionRank: Int) -> [Move] {
        guard to.rank == promotionRank else {
            return [Move(from: from, to: to)]
        }

        return [.queen, .rook, .bishop, .knight].map {
            Move(from: from, to: to, promotion: $0)
        }
    }

    private static func knightMoves(from square: Square, piece: Piece, in state: GameState) -> [Move] {
        let offsets = [
            (1, 2), (2, 1), (2, -1), (1, -2),
            (-1, -2), (-2, -1), (-2, 1), (-1, 2)
        ]

        return offsets.compactMap { fileOffset, rankOffset in
            guard let target = Square(file: square.file + fileOffset, rank: square.rank + rankOffset) else {
                return nil
            }
            if let pieceAtTarget = state.board.piece(at: target), pieceAtTarget.color == piece.color {
                return nil
            }
            return Move(from: square, to: target)
        }
    }

    private static func slidingMoves(from square: Square, piece: Piece, in state: GameState, directions: [(Int, Int)]) -> [Move] {
        var result: [Move] = []

        for (fileStep, rankStep) in directions {
            var file = square.file + fileStep
            var rank = square.rank + rankStep

            while let target = Square(file: file, rank: rank) {
                if let occupyingPiece = state.board.piece(at: target) {
                    if occupyingPiece.color != piece.color {
                        result.append(Move(from: square, to: target))
                    }
                    break
                }

                result.append(Move(from: square, to: target))
                file += fileStep
                rank += rankStep
            }
        }

        return result
    }

    private static func kingMoves(from square: Square, piece: Piece, in state: GameState) -> [Move] {
        var moves: [Move] = []

        for fileOffset in -1...1 {
            for rankOffset in -1...1 where !(fileOffset == 0 && rankOffset == 0) {
                guard let target = Square(file: square.file + fileOffset, rank: square.rank + rankOffset) else {
                    continue
                }
                if let targetPiece = state.board.piece(at: target), targetPiece.color == piece.color {
                    continue
                }
                moves.append(Move(from: square, to: target))
            }
        }

        moves.append(contentsOf: castlingMoves(from: square, piece: piece, in: state))
        return moves
    }

    private static func castlingMoves(from square: Square, piece: Piece, in state: GameState) -> [Move] {
        guard piece.type == .king else { return [] }

        let homeRank = piece.color == .white ? 0 : 7
        guard square.rank == homeRank, square.file == 4 else {
            return []
        }

        var castling: [Move] = []

        if canCastleKingSide(color: piece.color, homeRank: homeRank, in: state) {
            let destination = Square(file: 6, rank: homeRank)!
            castling.append(Move(from: square, to: destination, isCastling: true))
        }

        if canCastleQueenSide(color: piece.color, homeRank: homeRank, in: state) {
            let destination = Square(file: 2, rank: homeRank)!
            castling.append(Move(from: square, to: destination, isCastling: true))
        }

        return castling
    }

    private static func canCastleKingSide(color: PieceColor, homeRank: Int, in state: GameState) -> Bool {
        let rights = color == .white ? state.castlingRights.whiteKingSide : state.castlingRights.blackKingSide
        guard rights else { return false }

        let rookSquare = Square(file: 7, rank: homeRank)!
        guard state.board.piece(at: rookSquare) == Piece(color: color, type: .rook) else {
            return false
        }

        let fSquare = Square(file: 5, rank: homeRank)!
        let gSquare = Square(file: 6, rank: homeRank)!
        return state.board.piece(at: fSquare) == nil && state.board.piece(at: gSquare) == nil
    }

    private static func canCastleQueenSide(color: PieceColor, homeRank: Int, in state: GameState) -> Bool {
        let rights = color == .white ? state.castlingRights.whiteQueenSide : state.castlingRights.blackQueenSide
        guard rights else { return false }

        let rookSquare = Square(file: 0, rank: homeRank)!
        guard state.board.piece(at: rookSquare) == Piece(color: color, type: .rook) else {
            return false
        }

        let bSquare = Square(file: 1, rank: homeRank)!
        let cSquare = Square(file: 2, rank: homeRank)!
        let dSquare = Square(file: 3, rank: homeRank)!
        return state.board.piece(at: bSquare) == nil && state.board.piece(at: cSquare) == nil && state.board.piece(at: dSquare) == nil
    }
}
