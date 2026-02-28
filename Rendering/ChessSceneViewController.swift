import Foundation
import SceneKit
import UIKit

final class ChessSceneViewController: UIViewController {
    private let scnView = SCNView(frame: .zero)
    private let chessScene = ChessScene()
    private let inputMapper = InputMapper()

    private var lastHoverSquare: Square?

    var onSquareTapped: ((Square) -> Void)?
    var onSquareHovered: ((Square?) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupGestures()
    }

    func render(
        state: GameState,
        animatedMove: Move?,
        selectedSquare: Square?,
        legalSquares: [Square],
        hoveredSquare: Square?
    ) {
        chessScene.setBoard(
            state.board,
            animatedMove: animatedMove,
            status: state.status,
            checkedKing: state.checkedKing
        )
        chessScene.updateHighlights(selected: selectedSquare, legal: legalSquares, hovered: hoveredSquare)
    }

    private func setupView() {
        view.backgroundColor = .clear

        scnView.translatesAutoresizingMaskIntoConstraints = false
        scnView.scene = chessScene.scene
        scnView.antialiasingMode = .multisampling4X
        scnView.isJitteringEnabled = true
        scnView.preferredFramesPerSecond = 60
        scnView.rendersContinuously = false
        scnView.allowsCameraControl = true
        scnView.defaultCameraController.interactionMode = .orbitTurntable
        scnView.defaultCameraController.inertiaEnabled = true
        scnView.defaultCameraController.minimumVerticalAngle = -78
        scnView.defaultCameraController.maximumVerticalAngle = 18
        scnView.backgroundColor = UIColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 1.0)
        scnView.clipsToBounds = true

        view.addSubview(scnView)

        NSLayoutConstraint.activate([
            scnView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scnView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scnView.topAnchor.constraint(equalTo: view.topAnchor),
            scnView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tap)

        let hover = UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:)))
        scnView.addGestureRecognizer(hover)
    }

    @objc
    private func handleTap(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: scnView)
        guard let square = inputMapper.square(at: point, in: scnView) else {
            return
        }
        onSquareTapped?(square)
    }

    @objc
    private func handleHover(_ recognizer: UIHoverGestureRecognizer) {
        let point = recognizer.location(in: scnView)

        switch recognizer.state {
        case .began, .changed:
            let hovered = inputMapper.square(at: point, in: scnView)
            if hovered != lastHoverSquare {
                lastHoverSquare = hovered
                onSquareHovered?(hovered)
            }
        default:
            if lastHoverSquare != nil {
                lastHoverSquare = nil
                onSquareHovered?(nil)
            }
        }
    }
}
