import Foundation
import SceneKit
import UIKit

enum PieceNodeFactory {
    private static var prototypeCache: [String: SCNNode] = [:]

    private static let whiteMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.92, green: 0.95, blue: 1.0, alpha: 1.0)
        material.emission.contents = UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 0.15)
        material.specular.contents = UIColor.white
        material.reflective.contents = UIColor.white
        material.reflective.intensity = 0.82
        material.transparent.contents = UIColor.white.withAlphaComponent(0.90)
        material.transparency = 0.90
        material.metalness.contents = 0.04
        material.roughness.contents = 0.12
        material.fresnelExponent = 1.6
        material.lightingModel = .physicallyBased
        return material
    }()

    private static let blackMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.12, green: 0.16, blue: 0.23, alpha: 1.0)
        material.emission.contents = UIColor(red: 1.00, green: 0.31, blue: 0.85, alpha: 0.12)
        material.specular.contents = UIColor.white
        material.reflective.contents = UIColor.white
        material.reflective.intensity = 0.74
        material.transparent.contents = UIColor.white.withAlphaComponent(0.94)
        material.transparency = 0.94
        material.metalness.contents = 0.08
        material.roughness.contents = 0.16
        material.fresnelExponent = 1.6
        material.lightingModel = .physicallyBased
        return material
    }()

    private static let crownMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.78, green: 0.63, blue: 0.36, alpha: 1.0)
        material.emission.contents = UIColor(red: 0.78, green: 0.63, blue: 0.36, alpha: 0.16)
        material.specular.contents = UIColor.white
        material.reflective.contents = UIColor.white
        material.reflective.intensity = 0.40
        material.metalness.contents = 0.72
        material.roughness.contents = 0.24
        material.lightingModel = .physicallyBased
        return material
    }()

    static func makeNode(for piece: Piece, square: Square) -> SCNNode {
        let key = "\(piece.color.rawValue)_\(piece.type.rawValue)"
        let prototype = prototypeCache[key] ?? {
            let created = buildPrototype(for: piece)
            prototypeCache[key] = created
            return created
        }()

        let node = prototype.clone()
        node.name = InputMapper.pieceNodeName(for: piece, square: square)
        node.castsShadow = true
        return node
    }

    static func height(for pieceType: PieceType) -> Float {
        switch pieceType {
        case .pawn: return 0.55
        case .knight: return 0.70
        case .bishop: return 0.72
        case .rook: return 0.58
        case .queen: return 0.82
        case .king: return 0.92
        }
    }

    private static func buildPrototype(for piece: Piece) -> SCNNode {
        let root = SCNNode()

        let base = SCNCylinder(radius: 0.25, height: 0.08)
        base.materials = [material(for: piece.color)]
        let baseNode = SCNNode(geometry: base)
        baseNode.position.y = 0.04
        root.addChildNode(baseNode)

        switch piece.type {
        case .pawn:
            let body = SCNCapsule(capRadius: 0.14, height: 0.38)
            body.materials = [material(for: piece.color)]
            let bodyNode = SCNNode(geometry: body)
            bodyNode.position.y = 0.30
            root.addChildNode(bodyNode)

        case .rook:
            let body = SCNBox(width: 0.32, height: 0.38, length: 0.32, chamferRadius: 0.04)
            body.materials = [material(for: piece.color)]
            let bodyNode = SCNNode(geometry: body)
            bodyNode.position.y = 0.29
            root.addChildNode(bodyNode)

            let top = SCNBox(width: 0.40, height: 0.08, length: 0.40, chamferRadius: 0.03)
            top.materials = [material(for: piece.color)]
            let topNode = SCNNode(geometry: top)
            topNode.position.y = 0.50
            root.addChildNode(topNode)

        case .knight:
            let body = SCNCone(topRadius: 0.09, bottomRadius: 0.20, height: 0.54)
            body.materials = [material(for: piece.color)]
            let bodyNode = SCNNode(geometry: body)
            bodyNode.position.y = 0.38
            bodyNode.eulerAngles.z = -.pi / 10
            root.addChildNode(bodyNode)

        case .bishop:
            let body = SCNCone(topRadius: 0.05, bottomRadius: 0.18, height: 0.58)
            body.materials = [material(for: piece.color)]
            let bodyNode = SCNNode(geometry: body)
            bodyNode.position.y = 0.40
            root.addChildNode(bodyNode)

            let top = SCNSphere(radius: 0.07)
            top.materials = [material(for: piece.color)]
            let topNode = SCNNode(geometry: top)
            topNode.position.y = 0.67
            root.addChildNode(topNode)

        case .queen:
            let body = SCNCylinder(radius: 0.17, height: 0.62)
            body.materials = [material(for: piece.color)]
            let bodyNode = SCNNode(geometry: body)
            bodyNode.position.y = 0.39
            root.addChildNode(bodyNode)

            let crown = SCNTorus(ringRadius: 0.13, pipeRadius: 0.03)
            crown.materials = [crownMaterial]
            let crownNode = SCNNode(geometry: crown)
            crownNode.position.y = 0.72
            root.addChildNode(crownNode)

        case .king:
            let body = SCNCylinder(radius: 0.17, height: 0.68)
            body.materials = [material(for: piece.color)]
            let bodyNode = SCNNode(geometry: body)
            bodyNode.position.y = 0.42
            root.addChildNode(bodyNode)

            let crossVertical = SCNBox(width: 0.05, height: 0.19, length: 0.05, chamferRadius: 0.01)
            crossVertical.materials = [crownMaterial]
            let verticalNode = SCNNode(geometry: crossVertical)
            verticalNode.position.y = 0.79
            root.addChildNode(verticalNode)

            let crossHorizontal = SCNBox(width: 0.16, height: 0.04, length: 0.05, chamferRadius: 0.01)
            crossHorizontal.materials = [crownMaterial]
            let horizontalNode = SCNNode(geometry: crossHorizontal)
            horizontalNode.position.y = 0.79
            root.addChildNode(horizontalNode)
        }

        addInternalGlow(to: root, for: piece)

        return root
    }

    private static func addInternalGlow(to node: SCNNode, for piece: Piece) {
        let glowSphere = SCNSphere(radius: 0.065)
        let glowMaterial = SCNMaterial()
        let glowColor = piece.color == .white
            ? UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 1.0)
            : UIColor(red: 1.00, green: 0.31, blue: 0.85, alpha: 1.0)
        glowMaterial.diffuse.contents = UIColor.clear
        glowMaterial.emission.contents = glowColor.withAlphaComponent(0.30)
        glowMaterial.lightingModel = .constant
        glowMaterial.blendMode = .add
        glowMaterial.isDoubleSided = true
        glowSphere.materials = [glowMaterial]

        let glowNode = SCNNode(geometry: glowSphere)
        glowNode.position.y = 0.36
        node.addChildNode(glowNode)

        let pulseUp = SCNAction.fadeOpacity(to: 0.92, duration: 1.1)
        let pulseDown = SCNAction.fadeOpacity(to: 0.52, duration: 1.1)
        pulseUp.timingMode = .easeInEaseOut
        pulseDown.timingMode = .easeInEaseOut
        glowNode.opacity = 0.56
        glowNode.runAction(.repeatForever(.sequence([pulseUp, pulseDown])))
    }

    private static func material(for color: PieceColor) -> SCNMaterial {
        color == .white ? whiteMaterial : blackMaterial
    }
}
