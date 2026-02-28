import Foundation

enum PieceColor: String, Codable, CaseIterable, Hashable {
    case white
    case black

    var opposite: PieceColor {
        self == .white ? .black : .white
    }
}

enum PieceType: String, Codable, CaseIterable, Hashable {
    case king
    case queen
    case rook
    case bishop
    case knight
    case pawn
}

struct Piece: Codable, Equatable, Hashable {
    let color: PieceColor
    let type: PieceType
}
