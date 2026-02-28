import Foundation
import SceneKit
import UIKit

enum BoardNodeFactory {
    static let boardThickness: Float = 0.11
    static let squareSize: Float = 1.0

    static func makeBoardNode() -> SCNNode {
        let root = SCNNode()

        let lightGeometry = SCNBox(
            width: CGFloat(squareSize),
            height: CGFloat(boardThickness),
            length: CGFloat(squareSize),
            chamferRadius: 0.03
        )
        lightGeometry.materials = [lightSquareMaterial()]

        let darkGeometry = SCNBox(
            width: CGFloat(squareSize),
            height: CGFloat(boardThickness),
            length: CGFloat(squareSize),
            chamferRadius: 0.03
        )
        darkGeometry.materials = [darkSquareMaterial()]

        for rank in 0...7 {
            for file in 0...7 {
                guard let square = Square(file: file, rank: rank) else { continue }

                let node = SCNNode(geometry: ((file + rank).isMultiple(of: 2) ? lightGeometry : darkGeometry))
                node.name = InputMapper.squareName(for: square)
                node.position = SCNVector3(Float(file) - 3.5, 0, Float(rank) - 3.5)
                node.castsShadow = true
                root.addChildNode(node)
            }
        }

        let frameGeometry = SCNBox(width: 8.78, height: 0.16, length: 8.78, chamferRadius: 0.16)
        frameGeometry.materials = [frameMaterial()]
        let frameNode = SCNNode(geometry: frameGeometry)
        frameNode.position = SCNVector3(0, -0.035, 0)
        root.addChildNode(frameNode)

        let edgeGlowGeometry = SCNBox(width: 8.72, height: 0.01, length: 8.72, chamferRadius: 0.15)
        edgeGlowGeometry.materials = [edgeGlowMaterial()]
        let edgeGlowNode = SCNNode(geometry: edgeGlowGeometry)
        edgeGlowNode.position = SCNVector3(0, boardThickness / 2 + 0.011, 0)
        root.addChildNode(edgeGlowNode)

        root.addChildNode(makeSideAura(color: UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 1.0), centerZ: -2.8))
        root.addChildNode(makeSideAura(color: UIColor(red: 1.00, green: 0.31, blue: 0.85, alpha: 1.0), centerZ: 2.8))

        return root
    }

    private static func makeSideAura(color: UIColor, centerZ: Float) -> SCNNode {
        let auraPlane = SCNPlane(width: 8.0, height: 2.4)
        let auraMaterial = SCNMaterial()
        auraMaterial.diffuse.contents = color.withAlphaComponent(0.13)
        auraMaterial.emission.contents = color.withAlphaComponent(0.22)
        auraMaterial.lightingModel = .constant
        auraMaterial.isDoubleSided = true
        auraMaterial.blendMode = .add
        auraMaterial.writesToDepthBuffer = false
        auraPlane.materials = [auraMaterial]

        let auraNode = SCNNode(geometry: auraPlane)
        auraNode.eulerAngles.x = -.pi / 2
        auraNode.position = SCNVector3(0, boardThickness / 2 + 0.007, centerZ)
        return auraNode
    }

    private static func lightSquareMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.73, green: 0.79, blue: 0.87, alpha: 1.0)
        material.metalness.contents = 0.22
        material.roughness.contents = 0.20
        material.specular.contents = UIColor.white
        material.reflective.contents = UIColor.white
        material.reflective.intensity = 0.26
        material.emission.contents = UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 0.08)
        material.fresnelExponent = 1.4
        material.lightingModel = .physicallyBased
        return material
    }

    private static func darkSquareMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.14, green: 0.18, blue: 0.25, alpha: 1.0)
        material.metalness.contents = 0.30
        material.roughness.contents = 0.24
        material.specular.contents = UIColor.white
        material.reflective.contents = UIColor.white
        material.reflective.intensity = 0.34
        material.emission.contents = UIColor(red: 1.00, green: 0.31, blue: 0.85, alpha: 0.06)
        material.fresnelExponent = 1.5
        material.lightingModel = .physicallyBased
        return material
    }

    private static func frameMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.05, green: 0.07, blue: 0.10, alpha: 1.0)
        material.emission.contents = UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 0.05)
        material.metalness.contents = 0.38
        material.roughness.contents = 0.30
        material.specular.contents = UIColor.white
        material.reflective.contents = UIColor.white
        material.reflective.intensity = 0.40
        material.lightingModel = .physicallyBased
        return material
    }

    private static func edgeGlowMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear
        material.emission.contents = UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 0.50)
        material.blendMode = .add
        material.lightingModel = .constant
        material.writesToDepthBuffer = false
        return material
    }
}
