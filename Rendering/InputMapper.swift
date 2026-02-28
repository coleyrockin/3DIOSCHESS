import Foundation
import SceneKit
import UIKit

struct InputMapper {
    func square(at point: CGPoint, in view: SCNView) -> Square? {
        let hits = view.hitTest(point, options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
        for hit in hits {
            if let square = square(from: hit.node) {
                return square
            }
        }
        return nil
    }

    func square(from node: SCNNode?) -> Square? {
        var current = node
        while let node = current {
            if let name = node.name, let mapped = Self.square(fromName: name) {
                return mapped
            }
            current = node.parent
        }
        return nil
    }

    static func squareName(for square: Square) -> String {
        "square_\(square.algebraic)"
    }

    static func pieceNodeName(for piece: Piece, square: Square) -> String {
        "piece_\(piece.color.rawValue)_\(piece.type.rawValue)_\(square.algebraic)"
    }

    static func square(fromName name: String) -> Square? {
        if name.hasPrefix("square_") {
            let algebraic = String(name.dropFirst("square_".count))
            return Square(algebraic: algebraic)
        }

        if name.hasPrefix("piece_") {
            let components = name.split(separator: "_")
            guard let algebraic = components.last else { return nil }
            return Square(algebraic: String(algebraic))
        }

        return nil
    }
}
