import Foundation

enum GameStatus: String, Codable {
    case ongoing
    case check
    case checkmate
    case stalemate
}

enum GameMode: String, Codable {
    case hotSeat
    case localAI
    case online
}

struct CastlingRights: Codable, Equatable {
    var whiteKingSide: Bool
    var whiteQueenSide: Bool
    var blackKingSide: Bool
    var blackQueenSide: Bool

    static let initial = CastlingRights(
        whiteKingSide: true,
        whiteQueenSide: true,
        blackKingSide: true,
        blackQueenSide: true
    )
}

struct GameState: Codable, Equatable {
    var board: Board
    var turn: PieceColor
    var castlingRights: CastlingRights
    var enPassantTarget: Square?
    var halfmoveClock: Int
    var fullmoveNumber: Int
    var status: GameStatus
    var winner: PieceColor?
    var checkedKing: PieceColor?
    var capturedByWhite: [PieceType]
    var capturedByBlack: [PieceType]

    init(
        board: Board = Board(),
        turn: PieceColor = .white,
        castlingRights: CastlingRights = .initial,
        enPassantTarget: Square? = nil,
        halfmoveClock: Int = 0,
        fullmoveNumber: Int = 1,
        status: GameStatus = .ongoing,
        winner: PieceColor? = nil,
        checkedKing: PieceColor? = nil,
        capturedByWhite: [PieceType] = [],
        capturedByBlack: [PieceType] = []
    ) {
        self.board = board
        self.turn = turn
        self.castlingRights = castlingRights
        self.enPassantTarget = enPassantTarget
        self.halfmoveClock = halfmoveClock
        self.fullmoveNumber = fullmoveNumber
        self.status = status
        self.winner = winner
        self.checkedKing = checkedKing
        self.capturedByWhite = capturedByWhite
        self.capturedByBlack = capturedByBlack
    }
}
