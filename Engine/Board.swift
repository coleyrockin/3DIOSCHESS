import Foundation

struct Board: Codable, Equatable {
    private var storage: [Piece?]

    init(setupInitialPosition: Bool = true) {
        self.storage = Array(repeating: nil, count: 64)
        if setupInitialPosition {
            setInitialPosition()
        }
    }

    static var empty: Board {
        Board(setupInitialPosition: false)
    }

    func piece(at square: Square) -> Piece? {
        storage[index(for: square)]
    }

    mutating func setPiece(_ piece: Piece?, at square: Square) {
        storage[index(for: square)] = piece
    }

    mutating func movePiece(from: Square, to: Square) {
        let movingPiece = piece(at: from)
        setPiece(movingPiece, at: to)
        setPiece(nil, at: from)
    }

    func allPieces() -> [(Square, Piece)] {
        storage.enumerated().compactMap { index, piece in
            guard let piece else { return nil }
            let file = index % 8
            let rank = index / 8
            guard let square = Square(file: file, rank: rank) else { return nil }
            return (square, piece)
        }
    }

    func pieces(for color: PieceColor) -> [(Square, Piece)] {
        allPieces().filter { $0.1.color == color }
    }

    private func index(for square: Square) -> Int {
        square.rank * 8 + square.file
    }

    private mutating func setInitialPosition() {
        storage = Array(repeating: nil, count: 64)

        let backRank: [PieceType] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]

        for file in 0...7 {
            let whiteBack = Square(file: file, rank: 0)!
            let whitePawn = Square(file: file, rank: 1)!
            let blackPawn = Square(file: file, rank: 6)!
            let blackBack = Square(file: file, rank: 7)!

            setPiece(Piece(color: .white, type: backRank[file]), at: whiteBack)
            setPiece(Piece(color: .white, type: .pawn), at: whitePawn)
            setPiece(Piece(color: .black, type: .pawn), at: blackPawn)
            setPiece(Piece(color: .black, type: backRank[file]), at: blackBack)
        }
    }
}
