import Foundation
import SceneKit
import UIKit

final class ChessScene {
    let scene: SCNScene

    private let boardRoot = SCNNode()
    private let piecesRoot = SCNNode()
    private let highlighter: SelectionHighlighter
    private let cameraNode = SCNNode()
    private let keyLightNode = SCNNode()
    private let fillLightNode = SCNNode()
    private let rimLightNode = SCNNode()

    private var pieceNodes: [Square: SCNNode] = [:]
    private var isCheckmateEffectActive = false
    private var activeCheckKingSquare: Square?

    private let defaultCameraPosition = SCNVector3(0, 10.8, -9.1)
    private let defaultCameraEuler = SCNVector3(-.pi / 3.1, 0, 0)
    private let defaultAmbientIntensity: CGFloat = 340

    init() {
        scene = SCNScene()
        highlighter = SelectionHighlighter(squareSize: BoardNodeFactory.squareSize)
        setupScene()
    }

    func setBoard(_ board: Board, animatedMove: Move?, status: GameStatus, checkedKing: PieceColor?) {
        if let animatedMove {
            if pieceNodes[animatedMove.from] != nil {
                animate(move: animatedMove, resultingBoard: board)
            } else {
                rebuildPieces(with: board)
            }
        } else {
            rebuildPieces(with: board)
        }

        updateGameEffects(board: board, status: status, checkedKing: checkedKing)
    }

    func updateHighlights(selected: Square?, legal: [Square], hovered: Square?) {
        highlighter.update(selected: selected, legal: legal, hovered: hovered)
    }

    private func setupScene() {
        scene.background.contents = UIColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 1.0)
        scene.lightingEnvironment.contents = makeEnvironmentTexture()
        scene.lightingEnvironment.intensity = 1.25

        let boardNode = BoardNodeFactory.makeBoardNode()
        boardRoot.addChildNode(boardNode)
        scene.rootNode.addChildNode(boardRoot)
        scene.rootNode.addChildNode(piecesRoot)
        scene.rootNode.addChildNode(highlighter.rootNode)

        let camera = SCNCamera()
        camera.wantsHDR = true
        camera.wantsExposureAdaptation = true
        camera.zNear = 0.1
        camera.zFar = 120
        camera.bloomIntensity = 0.32
        camera.bloomThreshold = 0.4
        camera.bloomBlurRadius = 6
        cameraNode.camera = camera
        cameraNode.position = defaultCameraPosition
        cameraNode.eulerAngles = defaultCameraEuler
        scene.rootNode.addChildNode(cameraNode)

        let keyLight = SCNLight()
        keyLight.type = .omni
        keyLight.color = UIColor(red: 0.82, green: 0.92, blue: 1.0, alpha: 1.0)
        keyLight.intensity = 1180
        keyLight.castsShadow = true
        keyLight.shadowRadius = 3
        keyLight.shadowColor = UIColor.black.withAlphaComponent(0.35)
        keyLightNode.light = keyLight
        keyLightNode.position = SCNVector3(-2.2, 12.8, -6.4)
        scene.rootNode.addChildNode(keyLightNode)

        let fillLight = SCNLight()
        fillLight.type = .ambient
        fillLight.color = UIColor(red: 0.56, green: 0.62, blue: 0.74, alpha: 1.0)
        fillLight.intensity = defaultAmbientIntensity
        fillLightNode.light = fillLight
        scene.rootNode.addChildNode(fillLightNode)

        let rimLight = SCNLight()
        rimLight.type = .omni
        rimLight.color = UIColor(red: 1.0, green: 0.39, blue: 0.86, alpha: 1.0)
        rimLight.intensity = 380
        rimLightNode.light = rimLight
        rimLightNode.position = SCNVector3(2.6, 8.8, 5.8)
        scene.rootNode.addChildNode(rimLightNode)

        startCameraIdleMotion()
    }

    private func startCameraIdleMotion() {
        let driftA = SCNAction.group([
            .moveBy(x: 0.12, y: 0.08, z: 0.16, duration: 4.4),
            .rotateBy(x: 0.010, y: -0.008, z: 0.0, duration: 4.4)
        ])
        let driftB = SCNAction.group([
            .moveBy(x: -0.12, y: -0.08, z: -0.16, duration: 4.4),
            .rotateBy(x: -0.010, y: 0.008, z: 0.0, duration: 4.4)
        ])
        driftA.timingMode = .easeInEaseOut
        driftB.timingMode = .easeInEaseOut
        cameraNode.runAction(.repeatForever(.sequence([driftA, driftB])), forKey: "idleDrift")
    }

    private func rebuildPieces(with board: Board) {
        pieceNodes.values.forEach { $0.removeFromParentNode() }
        pieceNodes.removeAll()
        activeCheckKingSquare = nil

        let sortedPieces = board.allPieces().sorted { lhs, rhs in
            lhs.0 < rhs.0
        }

        for (square, piece) in sortedPieces {
            let node = PieceNodeFactory.makeNode(for: piece, square: square)
            node.position = position(for: square, pieceType: piece.type)
            piecesRoot.addChildNode(node)
            pieceNodes[square] = node
        }
    }

    private func animate(move: Move, resultingBoard: Board) {
        guard let movingNode = pieceNodes.removeValue(forKey: move.from) else {
            rebuildPieces(with: resultingBoard)
            return
        }

        if move.isEnPassant,
           let capturedSquare = Square(file: move.to.file, rank: move.from.rank),
           let capturedNode = pieceNodes.removeValue(forKey: capturedSquare) {
            removeNodeWithBurst(capturedNode)
        } else if let capturedNode = pieceNodes.removeValue(forKey: move.to) {
            removeNodeWithBurst(capturedNode)
        }

        if move.isCastling {
            animateCastlingRook(for: move)
        }

        if let destinationPiece = resultingBoard.piece(at: move.to) {
            let destination = position(for: move.to, pieceType: destinationPiece.type)
            attachMoveTrail(to: movingNode, duration: 0.34)
            let action = SCNAction.move(to: destination, duration: 0.34)
            action.timingMode = .easeInEaseOut
            movingNode.runAction(action)
        }

        pieceNodes[move.to] = movingNode

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { [weak self] in
            self?.rebuildPieces(with: resultingBoard)
        }
    }

    private func animateCastlingRook(for move: Move) {
        let homeRank = move.from.rank

        if move.to.file == 6 {
            let rookFrom = Square(file: 7, rank: homeRank)!
            let rookTo = Square(file: 5, rank: homeRank)!
            animateRook(from: rookFrom, to: rookTo)
        } else if move.to.file == 2 {
            let rookFrom = Square(file: 0, rank: homeRank)!
            let rookTo = Square(file: 3, rank: homeRank)!
            animateRook(from: rookFrom, to: rookTo)
        }
    }

    private func animateRook(from: Square, to: Square) {
        guard let rookNode = pieceNodes.removeValue(forKey: from) else {
            return
        }

        let destination = SCNVector3(Float(to.file) - 3.5, rookNode.position.y, Float(to.rank) - 3.5)
        attachMoveTrail(to: rookNode, duration: 0.28)
        let action = SCNAction.move(to: destination, duration: 0.28)
        action.timingMode = .easeInEaseOut
        rookNode.runAction(action)
        pieceNodes[to] = rookNode
    }

    private func attachMoveTrail(to node: SCNNode, duration: TimeInterval) {
        let trail = SCNParticleSystem()
        trail.birthRate = 260
        trail.particleLifeSpan = 0.24
        trail.particleLifeSpanVariation = 0.08
        trail.particleSize = 0.016
        trail.particleColor = UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 0.78)
        trail.particleVelocity = 0.12
        trail.particleVelocityVariation = 0.08
        trail.emitterShape = SCNSphere(radius: 0.02)
        trail.spreadingAngle = 36
        trail.isAffectedByGravity = false
        trail.blendMode = .additive
        trail.isLightingEnabled = false
        trail.emissionDuration = duration
        trail.loops = false

        node.addParticleSystem(trail)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.35) { [weak node] in
            node?.removeParticleSystem(trail)
        }
    }

    private func removeNodeWithBurst(_ node: SCNNode) {
        let burstSphere = SCNSphere(radius: 0.15)
        let burstMaterial = SCNMaterial()
        burstMaterial.diffuse.contents = UIColor.clear
        burstMaterial.emission.contents = UIColor(red: 1.0, green: 0.50, blue: 0.88, alpha: 0.9)
        burstMaterial.blendMode = .add
        burstMaterial.lightingModel = .constant
        burstSphere.materials = [burstMaterial]

        let burstNode = SCNNode(geometry: burstSphere)
        burstNode.position = node.position
        burstNode.opacity = 0.85
        piecesRoot.addChildNode(burstNode)

        let burstGrow = SCNAction.scale(to: 2.8, duration: 0.20)
        let burstFade = SCNAction.fadeOut(duration: 0.20)
        burstGrow.timingMode = .easeInEaseOut
        burstFade.timingMode = .easeInEaseOut
        burstNode.runAction(.sequence([.group([burstGrow, burstFade]), .removeFromParentNode()]))

        let fade = SCNAction.fadeOut(duration: 0.18)
        let shrink = SCNAction.scale(to: 0.6, duration: 0.18)
        fade.timingMode = .easeInEaseOut
        shrink.timingMode = .easeInEaseOut
        let remove = SCNAction.removeFromParentNode()
        node.runAction(.sequence([.group([fade, shrink]), remove]))
    }

    private func updateGameEffects(board: Board, status: GameStatus, checkedKing: PieceColor?) {
        applyCheckEffect(board: board, status: status, checkedKing: checkedKing)
        applyCheckmateEffect(status: status)
    }

    private func applyCheckEffect(board: Board, status: GameStatus, checkedKing: PieceColor?) {
        guard status == .check,
              let checkedKing,
              let kingSquare = kingSquare(for: checkedKing, in: board),
              let kingNode = pieceNodes[kingSquare] else {
            clearCheckIndicators()
            return
        }

        guard activeCheckKingSquare != kingSquare else { return }

        clearCheckIndicators()
        activeCheckKingSquare = kingSquare

        let pulseUp = SCNAction.scale(to: 1.08, duration: 0.42)
        let pulseDown = SCNAction.scale(to: 1.0, duration: 0.42)
        pulseUp.timingMode = .easeInEaseOut
        pulseDown.timingMode = .easeInEaseOut
        kingNode.runAction(.repeatForever(.sequence([pulseUp, pulseDown])), forKey: "checkPulse")

        let auraGeometry = SCNSphere(radius: 0.23)
        let auraMaterial = SCNMaterial()
        auraMaterial.diffuse.contents = UIColor.clear
        auraMaterial.emission.contents = UIColor(red: 1.0, green: 0.22, blue: 0.33, alpha: 0.75)
        auraMaterial.blendMode = .add
        auraMaterial.lightingModel = .constant
        auraGeometry.materials = [auraMaterial]

        let auraNode = SCNNode(geometry: auraGeometry)
        auraNode.name = "checkAura"
        auraNode.position = SCNVector3(0, 0.38, 0)
        auraNode.opacity = 0.58

        let auraUp = SCNAction.fadeOpacity(to: 1.0, duration: 0.42)
        let auraDown = SCNAction.fadeOpacity(to: 0.38, duration: 0.42)
        auraUp.timingMode = .easeInEaseOut
        auraDown.timingMode = .easeInEaseOut
        auraNode.runAction(.repeatForever(.sequence([auraUp, auraDown])))

        kingNode.addChildNode(auraNode)
    }

    private func clearCheckIndicators() {
        guard activeCheckKingSquare != nil else { return }

        pieceNodes.values.forEach {
            $0.removeAction(forKey: "checkPulse")
            $0.childNode(withName: "checkAura", recursively: false)?.removeFromParentNode()
            $0.scale = SCNVector3(1, 1, 1)
        }

        activeCheckKingSquare = nil
    }

    private func applyCheckmateEffect(status: GameStatus) {
        if status == .checkmate || status == .resigned {
            guard !isCheckmateEffectActive else { return }
            isCheckmateEffectActive = true

            cameraNode.removeAction(forKey: "idleDrift")
            let zoom = SCNAction.group([
                .move(to: SCNVector3(0, 10.0, -7.3), duration: 1.8),
                .rotateTo(x: CGFloat(-.pi / 3.45), y: 0, z: 0, duration: 1.8, usesShortestUnitArc: true)
            ])
            zoom.timingMode = .easeInEaseOut
            cameraNode.runAction(zoom, forKey: "checkmateZoom")

            let startIntensity = fillLightNode.light?.intensity ?? defaultAmbientIntensity
            let dimAction = SCNAction.customAction(duration: 1.8) { [weak self] _, elapsed in
                guard let self else { return }
                let progress = min(max(elapsed / 1.8, 0), 1)
                self.fillLightNode.light?.intensity = startIntensity - ((startIntensity - 170) * progress)
            }
            fillLightNode.runAction(dimAction, forKey: "checkmateDim")
            return
        }

        guard isCheckmateEffectActive else { return }
        isCheckmateEffectActive = false

        cameraNode.removeAction(forKey: "checkmateZoom")
        let reset = SCNAction.group([
            .move(to: defaultCameraPosition, duration: 0.66),
            .rotateTo(
                x: CGFloat(defaultCameraEuler.x),
                y: CGFloat(defaultCameraEuler.y),
                z: CGFloat(defaultCameraEuler.z),
                duration: 0.66,
                usesShortestUnitArc: true
            )
        ])
        reset.timingMode = .easeInEaseOut
        cameraNode.runAction(reset) { [weak self] in
            self?.startCameraIdleMotion()
        }

        fillLightNode.removeAction(forKey: "checkmateDim")
        fillLightNode.light?.intensity = defaultAmbientIntensity
    }

    private func kingSquare(for color: PieceColor, in board: Board) -> Square? {
        board.allPieces().first(where: { _, piece in
            piece.type == .king && piece.color == color
        })?.0
    }

    private func position(for square: Square, pieceType: PieceType) -> SCNVector3 {
        let x = Float(square.file) - 3.5
        let y = BoardNodeFactory.boardThickness / 2 + PieceNodeFactory.height(for: pieceType) / 2 + 0.01
        let z = Float(square.rank) - 3.5
        return SCNVector3(x, y, z)
    }

    private func makeEnvironmentTexture() -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let cgContext = context.cgContext
            let colors = [
                UIColor(red: 0.00, green: 0.83, blue: 1.00, alpha: 0.30).cgColor,
                UIColor(red: 0.48, green: 0.38, blue: 1.00, alpha: 0.22).cgColor,
                UIColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 1.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0, 0.45, 1]

            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else {
                return
            }

            let center = CGPoint(x: size.width * 0.75, y: size.height * 0.22)
            cgContext.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: size.width,
                options: .drawsAfterEndLocation
            )

            let centerTwo = CGPoint(x: size.width * 0.22, y: size.height * 0.82)
            let accentColors = [
                UIColor(red: 1.00, green: 0.31, blue: 0.85, alpha: 0.20).cgColor,
                UIColor.clear.cgColor
            ] as CFArray
            if let accentGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: accentColors, locations: [0, 1]) {
                cgContext.drawRadialGradient(
                    accentGradient,
                    startCenter: centerTwo,
                    startRadius: 0,
                    endCenter: centerTwo,
                    endRadius: size.width * 0.75,
                    options: .drawsAfterEndLocation
                )
            }
        }
    }
}
