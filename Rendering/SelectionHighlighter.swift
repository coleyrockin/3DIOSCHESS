import Foundation
import SceneKit
import UIKit

final class SelectionHighlighter {
    let rootNode = SCNNode()

    private let squareSize: Float
    private var overlayNodes: [Square: SCNNode] = [:]
    private var lastSelected: Square?

    init(squareSize: Float) {
        self.squareSize = squareSize
    }

    func update(selected: Square?, legal: [Square], hovered: Square?) {
        let legalSet = Set(legal)
        var activeSquares = legalSet
        if let selected { activeSquares.insert(selected) }
        if let hovered { activeSquares.insert(hovered) }

        for square in overlayNodes.keys where !activeSquares.contains(square) {
            overlayNodes[square]?.removeFromParentNode()
            overlayNodes[square] = nil
        }

        for square in activeSquares {
            let node = overlayNodes[square] ?? makeOverlayNode(for: square)
            overlayNodes[square] = node

            let style: HighlightStyle
            if square == selected {
                style = .selected
            } else if square == hovered {
                style = .hovered
            } else {
                style = .legal
            }

            apply(style: style, to: node)

            if style == .selected, square != lastSelected {
                runTapPulse(on: node)
            }
        }

        lastSelected = selected
    }

    private func makeOverlayNode(for square: Square) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(squareSize * 0.90), height: CGFloat(squareSize * 0.90))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 0.20)
        material.emission.contents = UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 0.36)
        material.isDoubleSided = true
        material.blendMode = .add
        material.lightingModel = .constant
        material.writesToDepthBuffer = false
        plane.materials = [material]

        let node = SCNNode(geometry: plane)
        node.name = "highlight_\(square.algebraic)"
        node.eulerAngles.x = -.pi / 2
        node.position = SCNVector3(Float(square.file) - 3.5, BoardNodeFactory.boardThickness / 2 + 0.006, Float(square.rank) - 3.5)
        node.opacity = 0.58
        rootNode.addChildNode(node)
        return node
    }

    private func apply(style: HighlightStyle, to node: SCNNode) {
        guard let material = node.geometry?.firstMaterial else { return }

        switch style {
        case .selected:
            material.diffuse.contents = UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 0.28)
            material.emission.contents = UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 0.58)
            node.removeAction(forKey: "hoverPulse")
            node.opacity = 0.84

        case .hovered:
            material.diffuse.contents = UIColor(red: 0.48, green: 0.38, blue: 1.00, alpha: 0.24)
            material.emission.contents = UIColor(red: 0.48, green: 0.38, blue: 1.00, alpha: 0.52)
            if node.action(forKey: "hoverPulse") == nil {
                let fadeUp = SCNAction.fadeOpacity(to: 0.90, duration: 0.36)
                let fadeDown = SCNAction.fadeOpacity(to: 0.52, duration: 0.36)
                fadeUp.timingMode = .easeInEaseOut
                fadeDown.timingMode = .easeInEaseOut
                node.runAction(.repeatForever(.sequence([fadeUp, fadeDown])), forKey: "hoverPulse")
            }

        case .legal:
            material.diffuse.contents = UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 0.18)
            material.emission.contents = UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 0.32)
            node.removeAction(forKey: "hoverPulse")
            node.opacity = 0.52
        }
    }

    private func runTapPulse(on node: SCNNode) {
        let up = SCNAction.scale(to: 1.08, duration: 0.10)
        let down = SCNAction.scale(to: 1.0, duration: 0.14)
        up.timingMode = .easeInEaseOut
        down.timingMode = .easeInEaseOut
        node.runAction(.sequence([up, down]), forKey: "tapPulse")
    }
}

private enum HighlightStyle {
    case selected
    case hovered
    case legal
}
