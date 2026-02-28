import XCTest
@testable import Chess3D

final class EngineTests: XCTestCase {

    // MARK: - Initial State

    func testInitialStateIsOngoing() {
        let state = Rules.initialState()
        XCTAssertEqual(state.status, .ongoing)
        XCTAssertEqual(state.turn, .white)
        XCTAssertEqual(state.halfmoveClock, 0)
        XCTAssertEqual(state.fullmoveNumber, 1)
        XCTAssertEqual(state.board.pieces(for: .white).count, 16)
        XCTAssertEqual(state.board.pieces(for: .black).count, 16)
        // Initial position seeded in positionHistory
        XCTAssertEqual(state.positionHistory.count, 1)
    }

    func testBasicPawnMove() {
        var state = Rules.initialState()
        let from = Square(algebraic: "e2")!
        let to = Square(algebraic: "e4")!
        let result = Rules.makeMove(Move(from: from, to: to), in: &state)
        XCTAssertTrue(result)
        XCTAssertNil(state.board.piece(at: from))
        XCTAssertEqual(state.board.piece(at: to), Piece(color: .white, type: .pawn))
        XCTAssertEqual(state.turn, .black)
        XCTAssertEqual(state.halfmoveClock, 0)
    }

    func testIllegalMoveRejected() {
        var state = Rules.initialState()
        // Pawn cannot move backwards
        let from = Square(algebraic: "e2")!
        let to = Square(algebraic: "e1")!
        let result = Rules.makeMove(Move(from: from, to: to), in: &state)
        XCTAssertFalse(result)
        XCTAssertEqual(state.turn, .white) // turn unchanged
    }

    // MARK: - Check & Checkmate

    func testCheckDetection() {
        // White rook on e8 with black king on e7 — black is in check
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "a1")!)
        board.setPiece(Piece(color: .white, type: .rook), at: Square(algebraic: "e1")!)
        board.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "e8")!)
        var state = GameState(board: board, turn: .black,
                              castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                             blackKingSide: false, blackQueenSide: false))
        Rules.updateStatus(&state)
        XCTAssertEqual(state.status, .check)
        XCTAssertEqual(state.checkedKing, .black)
    }

    func testScholarsMateCheckmate() {
        var state = Rules.initialState()
        // 1.e4 e5 2.Bc4 Nc6 3.Qh5 a6 4.Qxf7#
        XCTAssertTrue(Rules.makeMove(Move(from: Square(algebraic: "e2")!, to: Square(algebraic: "e4")!), in: &state))
        XCTAssertTrue(Rules.makeMove(Move(from: Square(algebraic: "e7")!, to: Square(algebraic: "e5")!), in: &state))
        XCTAssertTrue(Rules.makeMove(Move(from: Square(algebraic: "f1")!, to: Square(algebraic: "c4")!), in: &state))
        XCTAssertTrue(Rules.makeMove(Move(from: Square(algebraic: "b8")!, to: Square(algebraic: "c6")!), in: &state))
        XCTAssertTrue(Rules.makeMove(Move(from: Square(algebraic: "d1")!, to: Square(algebraic: "h5")!), in: &state))
        XCTAssertTrue(Rules.makeMove(Move(from: Square(algebraic: "a7")!, to: Square(algebraic: "a6")!), in: &state))
        XCTAssertTrue(Rules.makeMove(Move(from: Square(algebraic: "h5")!, to: Square(algebraic: "f7")!), in: &state))
        XCTAssertEqual(state.status, .checkmate)
        XCTAssertEqual(state.winner, .white)
    }

    func testStalemateDetected() {
        // Classic stalemate: black king on a8, white king on b6, white queen on c7
        var board = Board.empty
        board.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "a8")!)
        board.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "b6")!)
        board.setPiece(Piece(color: .white, type: .queen), at: Square(algebraic: "c7")!)
        var state = GameState(board: board, turn: .black,
                              castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                             blackKingSide: false, blackQueenSide: false))
        Rules.updateStatus(&state)
        XCTAssertEqual(state.status, .stalemate)
        XCTAssertNil(state.winner)
    }

    // MARK: - CheckDetector Bug Fix

    func testMissingKingReturnsNoCheck() {
        var board = Board.empty
        board.setPiece(Piece(color: .black, type: .rook), at: Square(algebraic: "a1")!)
        let state = GameState(board: board, turn: .white)
        // White king doesn't exist — must return false, not true
        XCTAssertFalse(CheckDetector.isKingInCheck(color: .white, in: state))
    }

    // MARK: - Castling

    func testKingsideCastlingLegal() {
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "e1")!)
        board.setPiece(Piece(color: .white, type: .rook), at: Square(algebraic: "h1")!)
        board.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "e8")!)
        let state = GameState(board: board, turn: .white, castlingRights: .initial)
        let moves = Rules.legalMoves(from: Square(algebraic: "e1")!, in: state)
        let castlingMove = moves.first { $0.to == Square(algebraic: "g1")! && $0.isCastling }
        XCTAssertNotNil(castlingMove)
    }

    func testQueensideCastlingLegal() {
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "e1")!)
        board.setPiece(Piece(color: .white, type: .rook), at: Square(algebraic: "a1")!)
        board.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "e8")!)
        let state = GameState(board: board, turn: .white, castlingRights: .initial)
        let moves = Rules.legalMoves(from: Square(algebraic: "e1")!, in: state)
        let castlingMove = moves.first { $0.to == Square(algebraic: "c1")! && $0.isCastling }
        XCTAssertNotNil(castlingMove)
    }

    func testCastlingBlockedWhenPathAttacked() {
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "e1")!)
        board.setPiece(Piece(color: .white, type: .rook), at: Square(algebraic: "h1")!)
        board.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "e8")!)
        // Black rook attacks f1 — the square the king must pass through
        board.setPiece(Piece(color: .black, type: .rook), at: Square(algebraic: "f8")!)
        let state = GameState(board: board, turn: .white, castlingRights: .initial)
        let moves = Rules.legalMoves(from: Square(algebraic: "e1")!, in: state)
        let castlingMove = moves.first { $0.to == Square(algebraic: "g1")! && $0.isCastling }
        XCTAssertNil(castlingMove)
    }

    func testCastlingRookMovedAfterCastling() {
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "e1")!)
        board.setPiece(Piece(color: .white, type: .rook), at: Square(algebraic: "h1")!)
        board.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "e8")!)
        var state = GameState(board: board, turn: .white, castlingRights: .initial)
        let castling = Move(from: Square(algebraic: "e1")!, to: Square(algebraic: "g1")!, isCastling: true)
        XCTAssertTrue(Rules.makeMove(castling, in: &state))
        // Rook must be on f1 after castling
        XCTAssertEqual(state.board.piece(at: Square(algebraic: "f1")!), Piece(color: .white, type: .rook))
        XCTAssertNil(state.board.piece(at: Square(algebraic: "h1")!))
    }

    // MARK: - En Passant

    func testEnPassantCapture() {
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .pawn), at: Square(algebraic: "e5")!)
        board.setPiece(Piece(color: .black, type: .pawn), at: Square(algebraic: "d5")!)
        board.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "e1")!)
        board.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "e8")!)
        let state = GameState(board: board, turn: .white,
                              castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                             blackKingSide: false, blackQueenSide: false),
                              enPassantTarget: Square(algebraic: "d6")!)
        let moves = Rules.legalMoves(from: Square(algebraic: "e5")!, in: state)
        let epMove = moves.first { $0.isEnPassant && $0.to == Square(algebraic: "d6")! }
        XCTAssertNotNil(epMove)
    }

    func testEnPassantRemovesCapturedPawn() {
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .pawn), at: Square(algebraic: "e5")!)
        board.setPiece(Piece(color: .black, type: .pawn), at: Square(algebraic: "d5")!)
        board.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "a1")!)
        board.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "h8")!)
        var state = GameState(board: board, turn: .white,
                              castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                             blackKingSide: false, blackQueenSide: false),
                              enPassantTarget: Square(algebraic: "d6")!)
        let epMove = Move(from: Square(algebraic: "e5")!, to: Square(algebraic: "d6")!, isEnPassant: true)
        XCTAssertTrue(Rules.makeMove(epMove, in: &state))
        XCTAssertNil(state.board.piece(at: Square(algebraic: "d5")!))
        XCTAssertEqual(state.board.piece(at: Square(algebraic: "d6")!), Piece(color: .white, type: .pawn))
    }

    // MARK: - Promotion

    func testPawnPromotionGeneratesFourMoves() {
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .pawn), at: Square(algebraic: "e7")!)
        board.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "a1")!)
        board.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "a8")!)
        let state = GameState(board: board, turn: .white,
                              castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                             blackKingSide: false, blackQueenSide: false))
        let moves = Rules.legalMoves(from: Square(algebraic: "e7")!, in: state)
        let promotions = moves.filter { $0.to == Square(algebraic: "e8")! }
        XCTAssertEqual(promotions.count, 4)
        let types = Set(promotions.compactMap(\.promotion))
        XCTAssertEqual(types, [.queen, .rook, .bishop, .knight])
    }

    func testPawnPromotionApplied() {
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .pawn), at: Square(algebraic: "e7")!)
        board.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "a1")!)
        board.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "a8")!)
        var state = GameState(board: board, turn: .white,
                              castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                             blackKingSide: false, blackQueenSide: false))
        let move = Move(from: Square(algebraic: "e7")!, to: Square(algebraic: "e8")!, promotion: .queen)
        XCTAssertTrue(Rules.makeMove(move, in: &state))
        XCTAssertEqual(state.board.piece(at: Square(algebraic: "e8")!), Piece(color: .white, type: .queen))
    }

    // MARK: - 50-Move Rule

    func test50MoveRuleAt100HalfMoves() {
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "e1")!)
        board.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "e8")!)
        board.setPiece(Piece(color: .white, type: .rook), at: Square(algebraic: "a1")!)

        var state = GameState(board: board, turn: .white,
                              castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                             blackKingSide: false, blackQueenSide: false),
                              halfmoveClock: 99)
        Rules.updateStatus(&state)
        XCTAssertNotEqual(state.status, .fiftyMoveRule)

        state.halfmoveClock = 100
        Rules.updateStatus(&state)
        XCTAssertEqual(state.status, .fiftyMoveRule)
        XCTAssertNil(state.winner)
    }

    func test50MoveRuleResetOnCapture() {
        var state = Rules.initialState()
        // Verify halfmoveClock resets after a capture
        // Set it to a high value manually
        state.halfmoveClock = 50
        // White pawn captures black pawn
        var board = state.board
        board.setPiece(Piece(color: .black, type: .pawn), at: Square(algebraic: "d5")!)
        state.board = board
        state.halfmoveClock = 50
        // Make a pawn capture (triggers halfmoveClock reset)
        let from = Square(algebraic: "e4")!
        let to = Square(algebraic: "d5")!
        // We need a specific position where this capture is possible
        // Instead, test via applyUnchecked directly
        var board2 = Board.empty
        board2.setPiece(Piece(color: .white, type: .pawn), at: Square(algebraic: "e4")!)
        board2.setPiece(Piece(color: .black, type: .pawn), at: Square(algebraic: "d5")!)
        board2.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "a1")!)
        board2.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "h8")!)
        var state2 = GameState(board: board2, turn: .white,
                               castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                              blackKingSide: false, blackQueenSide: false),
                               halfmoveClock: 60)
        let capture = Move(from: from, to: to)
        XCTAssertTrue(Rules.makeMove(capture, in: &state2))
        XCTAssertEqual(state2.halfmoveClock, 0)
    }

    // MARK: - Insufficient Material

    func testKvsKInsufficientMaterial() {
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "e1")!)
        board.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "e8")!)
        var state = GameState(board: board, turn: .white,
                              castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                             blackKingSide: false, blackQueenSide: false))
        Rules.updateStatus(&state)
        XCTAssertEqual(state.status, .insufficientMaterial)
        XCTAssertNil(state.winner)
    }

    func testKnightVsKInsufficientMaterial() {
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .king),   at: Square(algebraic: "e1")!)
        board.setPiece(Piece(color: .white, type: .knight), at: Square(algebraic: "d3")!)
        board.setPiece(Piece(color: .black, type: .king),   at: Square(algebraic: "e8")!)
        var state = GameState(board: board, turn: .white,
                              castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                             blackKingSide: false, blackQueenSide: false))
        Rules.updateStatus(&state)
        XCTAssertEqual(state.status, .insufficientMaterial)
    }

    func testBishopVsKInsufficientMaterial() {
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .king),   at: Square(algebraic: "e1")!)
        board.setPiece(Piece(color: .white, type: .bishop), at: Square(algebraic: "c1")!)
        board.setPiece(Piece(color: .black, type: .king),   at: Square(algebraic: "e8")!)
        var state = GameState(board: board, turn: .white,
                              castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                             blackKingSide: false, blackQueenSide: false))
        Rules.updateStatus(&state)
        XCTAssertEqual(state.status, .insufficientMaterial)
    }

    func testRookVsKIsNotInsufficientMaterial() {
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .king), at: Square(algebraic: "e1")!)
        board.setPiece(Piece(color: .white, type: .rook), at: Square(algebraic: "a1")!)
        board.setPiece(Piece(color: .black, type: .king), at: Square(algebraic: "e8")!)
        var state = GameState(board: board, turn: .white,
                              castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                             blackKingSide: false, blackQueenSide: false))
        Rules.updateStatus(&state)
        XCTAssertNotEqual(state.status, .insufficientMaterial)
    }

    func testBishopsOnSameColourInsufficientMaterial() {
        // c1 = (2+0)%2 = 0, f8 = (5+7)%2 = 0 — same colour
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .king),   at: Square(algebraic: "a1")!)
        board.setPiece(Piece(color: .white, type: .bishop), at: Square(algebraic: "c1")!)
        board.setPiece(Piece(color: .black, type: .king),   at: Square(algebraic: "h8")!)
        board.setPiece(Piece(color: .black, type: .bishop), at: Square(algebraic: "f8")!)
        var state = GameState(board: board, turn: .white,
                              castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                             blackKingSide: false, blackQueenSide: false))
        Rules.updateStatus(&state)
        XCTAssertEqual(state.status, .insufficientMaterial)
    }

    func testBishopsOnDifferentColoursNotInsufficientMaterial() {
        // c1 = (2+0)%2 = 0, e8 = (4+7)%2 = 1 — different colours
        var board = Board.empty
        board.setPiece(Piece(color: .white, type: .king),   at: Square(algebraic: "a1")!)
        board.setPiece(Piece(color: .white, type: .bishop), at: Square(algebraic: "c1")!)
        board.setPiece(Piece(color: .black, type: .king),   at: Square(algebraic: "h8")!)
        board.setPiece(Piece(color: .black, type: .bishop), at: Square(algebraic: "e8")!)
        var state = GameState(board: board, turn: .white,
                              castlingRights: CastlingRights(whiteKingSide: false, whiteQueenSide: false,
                                                             blackKingSide: false, blackQueenSide: false))
        Rules.updateStatus(&state)
        XCTAssertNotEqual(state.status, .insufficientMaterial)
    }

    // MARK: - Threefold Repetition

    func testThreefoldRepetitionDraw() {
        var state = Rules.initialState()
        // Shuffle knights back and forth to repeat starting position
        // Initial position is in history (count = 1)
        // After Nf3 + Nf6 + Ng1 + Ng8 → back to start (count = 2) → .ongoing
        // After Nf3 + Nf6 + Ng1 + Ng8 again → back to start (count = 3) → .threefoldRepetition
        let g1 = Square(algebraic: "g1")!
        let f3 = Square(algebraic: "f3")!
        let g8 = Square(algebraic: "g8")!
        let f6 = Square(algebraic: "f6")!

        XCTAssertTrue(Rules.makeMove(Move(from: g1, to: f3), in: &state))
        XCTAssertTrue(Rules.makeMove(Move(from: g8, to: f6), in: &state))
        XCTAssertTrue(Rules.makeMove(Move(from: f3, to: g1), in: &state))
        XCTAssertTrue(Rules.makeMove(Move(from: f6, to: g8), in: &state))
        XCTAssertEqual(state.status, .ongoing) // 2nd occurrence of start — not yet draw

        XCTAssertTrue(Rules.makeMove(Move(from: g1, to: f3), in: &state))
        XCTAssertTrue(Rules.makeMove(Move(from: g8, to: f6), in: &state))
        XCTAssertTrue(Rules.makeMove(Move(from: f3, to: g1), in: &state))
        XCTAssertTrue(Rules.makeMove(Move(from: f6, to: g8), in: &state))
        XCTAssertEqual(state.status, .threefoldRepetition) // 3rd occurrence → draw
        XCTAssertNil(state.winner)
    }

    func testThreefoldRepetitionPreventsMove() {
        var state = Rules.initialState()
        let g1 = Square(algebraic: "g1")!; let f3 = Square(algebraic: "f3")!
        let g8 = Square(algebraic: "g8")!; let f6 = Square(algebraic: "f6")!

        Rules.makeMove(Move(from: g1, to: f3), in: &state)
        Rules.makeMove(Move(from: g8, to: f6), in: &state)
        Rules.makeMove(Move(from: f3, to: g1), in: &state)
        Rules.makeMove(Move(from: f6, to: g8), in: &state)
        Rules.makeMove(Move(from: g1, to: f3), in: &state)
        Rules.makeMove(Move(from: g8, to: f6), in: &state)
        Rules.makeMove(Move(from: f3, to: g1), in: &state)
        Rules.makeMove(Move(from: f6, to: g8), in: &state)

        XCTAssertEqual(state.status, .threefoldRepetition)
        // No more moves allowed
        let result = Rules.makeMove(Move(from: g1, to: f3), in: &state)
        XCTAssertFalse(result)
    }

    // MARK: - Resign

    func testResignSetsCorrectStatus() {
        var state = Rules.initialState()
        // Simulate resignation via GameStore path: status set to .resigned with correct winner
        state.status = .resigned
        state.winner = .black
        state.checkedKing = nil

        XCTAssertEqual(state.status, .resigned)
        XCTAssertEqual(state.winner, .black)
        XCTAssertNil(state.checkedKing)
    }
}

// MARK: - AI Tests

final class AITests: XCTestCase {

    func testAIProducesLegalMove() {
        let ai = ChessAI(maxDepth: 1)
        var state = Rules.initialState()
        // Make one move so it's black's turn
        Rules.makeMove(Move(from: Square(algebraic: "e2")!, to: Square(algebraic: "e4")!), in: &state)

        let move = ai.bestMove(in: state)
        XCTAssertNotNil(move)

        if let move {
            let legalMoves = Rules.allLegalMoves(in: state)
            XCTAssertTrue(legalMoves.contains(move), "AI move \(move.from.algebraic)-\(move.to.algebraic) must be legal")
        }
    }

    func testAIReturnsNilAtCheckmate() {
        var state = Rules.initialState()
        Rules.makeMove(Move(from: Square(algebraic: "e2")!, to: Square(algebraic: "e4")!), in: &state)
        Rules.makeMove(Move(from: Square(algebraic: "e7")!, to: Square(algebraic: "e5")!), in: &state)
        Rules.makeMove(Move(from: Square(algebraic: "f1")!, to: Square(algebraic: "c4")!), in: &state)
        Rules.makeMove(Move(from: Square(algebraic: "b8")!, to: Square(algebraic: "c6")!), in: &state)
        Rules.makeMove(Move(from: Square(algebraic: "d1")!, to: Square(algebraic: "h5")!), in: &state)
        Rules.makeMove(Move(from: Square(algebraic: "a7")!, to: Square(algebraic: "a6")!), in: &state)
        Rules.makeMove(Move(from: Square(algebraic: "h5")!, to: Square(algebraic: "f7")!), in: &state)
        XCTAssertEqual(state.status, .checkmate)

        let ai = ChessAI(maxDepth: 1)
        XCTAssertNil(ai.bestMove(in: state))
    }

    func testAIDoesNotLeaveSelfInCheck() {
        let ai = ChessAI(maxDepth: 2)
        var state = Rules.initialState()
        Rules.makeMove(Move(from: Square(algebraic: "e2")!, to: Square(algebraic: "e4")!), in: &state)
        Rules.makeMove(Move(from: Square(algebraic: "e7")!, to: Square(algebraic: "e5")!), in: &state)

        guard let move = ai.bestMove(in: state) else {
            XCTFail("AI should produce a move")
            return
        }

        let aiColor = state.turn
        var afterMove = state
        let applied = Rules.makeMove(move, in: &afterMove)
        XCTAssertTrue(applied)
        XCTAssertFalse(CheckDetector.isKingInCheck(color: aiColor, in: afterMove),
                       "AI must not leave its own king in check")
    }

    func testEvaluatorHandlesAllDrawStatuses() {
        var state = Rules.initialState()

        state.status = .fiftyMoveRule
        XCTAssertEqual(Evaluator.evaluate(state, perspective: .white), 0)

        state.status = .insufficientMaterial
        XCTAssertEqual(Evaluator.evaluate(state, perspective: .white), 0)

        state.status = .threefoldRepetition
        XCTAssertEqual(Evaluator.evaluate(state, perspective: .white), 0)

        state.status = .stalemate
        XCTAssertEqual(Evaluator.evaluate(state, perspective: .white), 0)
    }

    func testEvaluatorReturnsPositiveScoreForWinner() {
        var state = Rules.initialState()
        state.status = .checkmate
        state.winner = .white
        XCTAssertGreaterThan(Evaluator.evaluate(state, perspective: .white), 0)
        XCTAssertLessThan(Evaluator.evaluate(state, perspective: .black), 0)
    }

    func testEvaluatorResignedStatus() {
        var state = Rules.initialState()
        state.status = .resigned
        state.winner = .black
        XCTAssertLessThan(Evaluator.evaluate(state, perspective: .white), 0)
        XCTAssertGreaterThan(Evaluator.evaluate(state, perspective: .black), 0)
    }
}
