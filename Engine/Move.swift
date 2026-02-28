import Foundation

struct Square: Codable, Hashable, Comparable {
    let file: Int
    let rank: Int

    init?(file: Int, rank: Int) {
        guard (0...7).contains(file), (0...7).contains(rank) else {
            return nil
        }
        self.file = file
        self.rank = rank
    }

    init?(algebraic: String) {
        guard algebraic.count == 2 else { return nil }
        let chars = Array(algebraic.lowercased())
        guard let fileAscii = chars.first?.asciiValue,
              let rankAscii = chars.last?.asciiValue else {
            return nil
        }
        let file = Int(fileAscii) - Int(Character("a").asciiValue!)
        let rank = Int(rankAscii) - Int(Character("1").asciiValue!)
        self.init(file: file, rank: rank)
    }

    var algebraic: String {
        let fileScalar = UnicodeScalar(Int(Character("a").asciiValue!) + file)!
        return "\(Character(fileScalar))\(rank + 1)"
    }

    static func < (lhs: Square, rhs: Square) -> Bool {
        if lhs.rank == rhs.rank {
            return lhs.file < rhs.file
        }
        return lhs.rank < rhs.rank
    }
}

struct Move: Codable, Hashable {
    let from: Square
    let to: Square
    var promotion: PieceType?
    var isEnPassant: Bool
    var isCastling: Bool

    init(
        from: Square,
        to: Square,
        promotion: PieceType? = nil,
        isEnPassant: Bool = false,
        isCastling: Bool = false
    ) {
        self.from = from
        self.to = to
        self.promotion = promotion
        self.isEnPassant = isEnPassant
        self.isCastling = isCastling
    }
}
