import Foundation

enum Rules {
    static func initialState() -> GameState {
        var state = GameState()
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
        state.status = .ongoing
        state.winner = nil
        state.checkedKing = nil
    }

    static func updateStatus(_ state: inout GameState) {
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
            if let nonPromotion = legalMoves.first(where: {
                $0.from == attemptedMove.from &&
                $0.to == attemptedMove.to &&
                $0.promotion == nil
            }) {
                return nonPromotion
            }

            if let queenPromotion = legalMoves.first(where: {
                $0.from == attemptedMove.from &&
                $0.to == attemptedMove.to &&
                $0.promotion == .queen
            }) {
                return queenPromotion
            }
        }

        return nil
    }

    private static func applyCastlingRookMove(for move: Move, color: PieceColor, state: inout GameState) {
        let homeRank = color == .white ? 0 : 7

        if move.to.file == 6 {
            let rookFrom = Square(file: 7, rank: homeRank)!
            let rookTo = Square(file: 5, rank: homeRank)!
            state.board.movePiece(from: rookFrom, to: rookTo)
        } else if move.to.file == 2 {
            let rookFrom = Square(file: 0, rank: homeRank)!
            let rookTo = Square(file: 3, rank: homeRank)!
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
}
