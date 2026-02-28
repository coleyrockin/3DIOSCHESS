import Foundation

enum Rules {
    static func initialState() -> GameState {
        var state = GameState()
        state.positionHistory.append(positionKey(for: state))
        updateStatus(&state)
        return state
    }

    static func legalMoves(from square: Square, in state: GameState) -> [Move] {
        LegalMoveFilter.legalMoves(from: square, in: state)
    }

    static func allLegalMoves(in state: GameState) -> [Move] {
        LegalMoveFilter.legalMoves(for: state.turn, in: state)
    }

    @discardableResult
    static func makeMove(_ attemptedMove: Move, in state: inout GameState) -> Bool {
        guard state.status == .ongoing || state.status == .check else {
            return false
        }
        guard let movingPiece = state.board.piece(at: attemptedMove.from), movingPiece.color == state.turn else {
            return false
        }

        let legal = LegalMoveFilter.legalMoves(from: attemptedMove.from, in: state)
        guard let move = resolveMove(attemptedMove, from: legal) else {
            return false
        }

        applyUnchecked(move, in: &state)
        updateStatus(&state)
        return true
    }

    static func applyUnchecked(_ move: Move, in state: inout GameState) {
        guard var movingPiece = state.board.piece(at: move.from) else {
            return
        }

        let isPawnMove = movingPiece.type == .pawn

        var capturedPiece: Piece?
        if move.isEnPassant {
            let captureRank = move.to.rank + (movingPiece.color == .white ? -1 : 1)
            if let captureSquare = Square(file: move.to.file, rank: captureRank) {
                capturedPiece = state.board.piece(at: captureSquare)
                state.board.setPiece(nil, at: captureSquare)
            }
        } else {
            capturedPiece = state.board.piece(at: move.to)
        }

        if let capturedPiece {
            if movingPiece.color == .white {
                state.capturedByWhite.append(capturedPiece.type)
            } else {
                state.capturedByBlack.append(capturedPiece.type)
            }
        }

        updateCastlingRightsForCapture(capturedPiece: capturedPiece, captureSquare: move.to, state: &state)

        state.board.movePiece(from: move.from, to: move.to)

        if movingPiece.type == .pawn {
            let promotionRank = movingPiece.color == .white ? 7 : 0
            if move.to.rank == promotionRank {
                movingPiece = Piece(color: movingPiece.color, type: move.promotion ?? .queen)
                state.board.setPiece(movingPiece, at: move.to)
            }
        }

        if move.isCastling {
            applyCastlingRookMove(for: move, color: movingPiece.color, state: &state)
        }

        updateCastlingRightsForMove(move: move, movingPiece: movingPiece, state: &state)

        if isPawnMove, abs(move.to.rank - move.from.rank) == 2 {
            let intermediateRank = (move.to.rank + move.from.rank) / 2
            state.enPassantTarget = Square(file: move.from.file, rank: intermediateRank)
        } else {
            state.enPassantTarget = nil
        }

        if isPawnMove || capturedPiece != nil {
            state.halfmoveClock = 0
        } else {
            state.halfmoveClock += 1
        }

        if movingPiece.color == .black {
            state.fullmoveNumber += 1
        }

        state.turn = movingPiece.color.opposite
        state.positionHistory.append(positionKey(for: state))
        state.status = .ongoing
        state.winner = nil
        state.checkedKing = nil
    }

    static func updateStatus(_ state: inout GameState) {
        // Draw: 50-move rule (100 half-moves = 50 full moves without pawn move or capture)
        if state.halfmoveClock >= 100 {
            state.status = .fiftyMoveRule
            state.winner = nil
            state.checkedKing = nil
            return
        }

        // Draw: insufficient material
        if hasInsufficientMaterial(state) {
            state.status = .insufficientMaterial
            state.winner = nil
            state.checkedKing = nil
            return
        }

        // Draw: threefold repetition
        if isThreefoldRepetition(state) {
            state.status = .threefoldRepetition
            state.winner = nil
            state.checkedKing = nil
            return
        }

        let currentPlayer = state.turn
        let inCheck = CheckDetector.isKingInCheck(color: currentPlayer, in: state)
        let legalMoves = LegalMoveFilter.legalMoves(for: currentPlayer, in: state)

        if legalMoves.isEmpty {
            if inCheck {
                state.status = .checkmate
                state.winner = currentPlayer.opposite
                state.checkedKing = currentPlayer
            } else {
                state.status = .stalemate
                state.winner = nil
                state.checkedKing = nil
            }
            return
        }

        if inCheck {
            state.status = .check
            state.checkedKing = currentPlayer
            state.winner = nil
        } else {
            state.status = .ongoing
            state.checkedKing = nil
            state.winner = nil
        }
    }

    private static func resolveMove(_ attemptedMove: Move, from legalMoves: [Move]) -> Move? {
        if let exact = legalMoves.first(where: {
            $0.from == attemptedMove.from &&
            $0.to == attemptedMove.to &&
            $0.promotion == attemptedMove.promotion
        }) {
            return exact
        }

        if attemptedMove.promotion == nil {
            return legalMoves.first(where: {
                $0.from == attemptedMove.from &&
                $0.to == attemptedMove.to &&
                $0.promotion == nil
            })
        }

        return nil
    }

    private static func applyCastlingRookMove(for move: Move, color: PieceColor, state: inout GameState) {
        let homeRank = color == .white ? 0 : 7

        // These squares are always valid (file 0-7, rank 0 or 7)
        if move.to.file == 6 {
            guard let rookFrom = Square(file: 7, rank: homeRank),
                  let rookTo = Square(file: 5, rank: homeRank) else { return }
            state.board.movePiece(from: rookFrom, to: rookTo)
        } else if move.to.file == 2 {
            guard let rookFrom = Square(file: 0, rank: homeRank),
                  let rookTo = Square(file: 3, rank: homeRank) else { return }
            state.board.movePiece(from: rookFrom, to: rookTo)
        }
    }

    private static func updateCastlingRightsForMove(move: Move, movingPiece: Piece, state: inout GameState) {
        if movingPiece.type == .king {
            if movingPiece.color == .white {
                state.castlingRights.whiteKingSide = false
                state.castlingRights.whiteQueenSide = false
            } else {
                state.castlingRights.blackKingSide = false
                state.castlingRights.blackQueenSide = false
            }
        }

        if movingPiece.type == .rook {
            switch (movingPiece.color, move.from.file, move.from.rank) {
            case (.white, 0, 0):
                state.castlingRights.whiteQueenSide = false
            case (.white, 7, 0):
                state.castlingRights.whiteKingSide = false
            case (.black, 0, 7):
                state.castlingRights.blackQueenSide = false
            case (.black, 7, 7):
                state.castlingRights.blackKingSide = false
            default:
                break
            }
        }
    }

    private static func updateCastlingRightsForCapture(capturedPiece: Piece?, captureSquare: Square, state: inout GameState) {
        guard let capturedPiece, capturedPiece.type == .rook else {
            return
        }

        switch (capturedPiece.color, captureSquare.file, captureSquare.rank) {
        case (.white, 0, 0):
            state.castlingRights.whiteQueenSide = false
        case (.white, 7, 0):
            state.castlingRights.whiteKingSide = false
        case (.black, 0, 7):
            state.castlingRights.blackQueenSide = false
        case (.black, 7, 7):
            state.castlingRights.blackKingSide = false
        default:
            break
        }
    }

    // MARK: - Draw helpers

    // Position key format (for threefold repetition):
    //   64 chars: piece letter per square (rank 0..7, file 0..7), '.' for empty
    //   1 char:   side to move ('w'/'b')
    //   4 chars:  castling rights (K/Q/k/q or '-' each)
    //   1–2 chars: en-passant target algebraic or '-'
    // Encodes everything that determines whether two positions are "the same"
    // under FIDE threefold-repetition rules.
    private static func positionKey(for state: GameState) -> String {
        var key = ""
        key.reserveCapacity(70)
        for rank in 0...7 {
            for file in 0...7 {
                if let square = Square(file: file, rank: rank),
                   let piece = state.board.piece(at: square) {
                    let letter: Character
                    switch piece.type {
                    case .king:   letter = piece.color == .white ? "K" : "k"
                    case .queen:  letter = piece.color == .white ? "Q" : "q"
                    case .rook:   letter = piece.color == .white ? "R" : "r"
                    case .bishop: letter = piece.color == .white ? "B" : "b"
                    case .knight: letter = piece.color == .white ? "N" : "n"
                    case .pawn:   letter = piece.color == .white ? "P" : "p"
                    }
                    key.append(letter)
                } else {
                    key.append(".")
                }
            }
        }
        key.append(state.turn == .white ? "w" : "b")
        let cr = state.castlingRights
        key.append(cr.whiteKingSide  ? "K" : "-")
        key.append(cr.whiteQueenSide ? "Q" : "-")
        key.append(cr.blackKingSide  ? "k" : "-")
        key.append(cr.blackQueenSide ? "q" : "-")
        key.append(contentsOf: state.enPassantTarget?.algebraic ?? "-")
        return key
    }

    private static func isThreefoldRepetition(_ state: GameState) -> Bool {
        guard !state.positionHistory.isEmpty else { return false }
        let currentKey = positionKey(for: state)
        return state.positionHistory.filter({ $0 == currentKey }).count >= 3
    }

    private static func hasInsufficientMaterial(_ state: GameState) -> Bool {
        let whitePieces = state.board.pieces(for: .white)
        let blackPieces = state.board.pieces(for: .black)

        let sufficientTypes: Set<PieceType> = [.pawn, .queen, .rook]
        let whiteNonKing = whitePieces.filter { $0.1.type != .king }
        let blackNonKing = blackPieces.filter { $0.1.type != .king }

        if whiteNonKing.contains(where: { sufficientTypes.contains($0.1.type) }) { return false }
        if blackNonKing.contains(where: { sufficientTypes.contains($0.1.type) }) { return false }

        // K vs K
        if whiteNonKing.isEmpty && blackNonKing.isEmpty { return true }

        // K+minor vs K
        if whiteNonKing.count == 1 && blackNonKing.isEmpty { return true }
        if blackNonKing.count == 1 && whiteNonKing.isEmpty { return true }

        // K+B vs K+B on same square colour
        if whiteNonKing.count == 1 && blackNonKing.count == 1,
           whiteNonKing[0].1.type == .bishop,
           blackNonKing[0].1.type == .bishop {
            let wSquare = whiteNonKing[0].0
            let bSquare = blackNonKing[0].0
            return (wSquare.file + wSquare.rank) % 2 == (bSquare.file + bSquare.rank) % 2
        }

        return false
    }
}
