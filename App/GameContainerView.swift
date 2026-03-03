import SwiftUI
import UIKit

struct GameContainerView: View {
    @ObservedObject var store: GameStore
    let showHUDBelowBoard: Bool

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding = max(12, geometry.size.width * 0.035)
            let verticalPadding = max(12, geometry.size.height * 0.025)
            let verticalSpacing = max(14, geometry.size.height * 0.024)
            let boardHeightRatio = showHUDBelowBoard ? 0.68 : 0.92

            let boardSide = max(
                180,
                min(
                    geometry.size.width - (horizontalPadding * 2),
                    geometry.size.height * boardHeightRatio
                )
            )

            VStack(spacing: verticalSpacing) {
                boardContainer(boardSide: boardSide)

                if showHUDBelowBoard {
                    GameHUDView(store: store)
                }

                Button("Deselect") {
                    store.deselect()
                }
                .keyboardShortcut(.cancelAction)
                .opacity(0.001)
                .frame(width: 1, height: 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
        }
        .background(FuturisticBackground())
    }

    @ViewBuilder
    private func boardContainer(boardSide: CGFloat) -> some View {
        let cornerRadius = max(16, boardSide * 0.045)

        ZStack {
            ChessSceneContainer(store: store)
                .frame(width: boardSide, height: boardSide)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: max(1.0, boardSide * 0.003))
                        .allowsHitTesting(false)
                }

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            DesignSystem.neonBlue.opacity(0.45),
                            DesignSystem.accentPurple.opacity(0.30),
                            DesignSystem.glowPink.opacity(0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1.6, boardSide * 0.004)
                )
                .blur(radius: 1.0)
                .allowsHitTesting(false)
        }
        .padding(10)
        .glassPanel(cornerRadius: cornerRadius + 8)
        .shadow(color: DesignSystem.neonBlue.opacity(0.18), radius: 30, x: 0, y: 12)
    }
}

struct GameHUDView: View {
    @ObservedObject var store: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(DesignSystem.textPrimary)

            Text("Turn: \(store.state.turn == .white ? "White" : "Black")")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(DesignSystem.textPrimary)

            Text(statusText)
                .font(.system(size: DesignSystem.minimumBodyFont, weight: .medium, design: .rounded))
                .foregroundStyle(statusColor)

            Text("Captured by White: \(capturedText(store.state.capturedByWhite, color: .black))")
                .font(.system(size: DesignSystem.minimumBodyFont, weight: .regular, design: .rounded))
                .foregroundStyle(DesignSystem.textSecondary)

            Text("Captured by Black: \(capturedText(store.state.capturedByBlack, color: .white))")
                .font(.system(size: DesignSystem.minimumBodyFont, weight: .regular, design: .rounded))
                .foregroundStyle(DesignSystem.textSecondary)

            if store.mode == .online {
                Text(store.isLocalPlayersTurn ? "Your move" : "Opponent move")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(DesignSystem.neonBlue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassPanel(cornerRadius: 18)
    }

    private var statusText: String {
        switch store.state.status {
        case .ongoing:
            return "Game in progress"
        case .check:
            guard let checked = store.state.checkedKing else {
                return "Check"
            }
            return "\(checked == .white ? "White" : "Black") is in check"
        case .checkmate:
            if let winner = store.state.winner {
                return "Checkmate. \(winner == .white ? "White" : "Black") wins"
            }
            return "Checkmate"
        case .stalemate:
            return "Stalemate — draw"
        case .fiftyMoveRule:
            return "Draw — 50-move rule"
        case .insufficientMaterial:
            return "Draw — insufficient material"
        case .threefoldRepetition:
            return "Draw — threefold repetition"
        case .resigned:
            if let winner = store.state.winner {
                return "\(winner == .white ? "White" : "Black") wins by resignation"
            }
            return "Resigned"
        }
    }

    private var statusColor: Color {
        switch store.state.status {
        case .ongoing:
            return DesignSystem.textSecondary
        case .check:
            return DesignSystem.glowPink
        case .checkmate, .resigned:
            return DesignSystem.gold
        case .stalemate, .fiftyMoveRule, .insufficientMaterial, .threefoldRepetition:
            return DesignSystem.accentPurple
        }
    }

    private func capturedText(_ pieces: [PieceType], color: PieceColor) -> String {
        guard !pieces.isEmpty else { return "-" }
        return pieces.map { symbol(for: $0, color: color) }.joined(separator: " ")
    }

    private func symbol(for type: PieceType, color: PieceColor) -> String {
        let base: String
        switch type {
        case .king: base = "K"
        case .queen: base = "Q"
        case .rook: base = "R"
        case .bishop: base = "B"
        case .knight: base = "N"
        case .pawn: base = "P"
        }
        return color == .white ? base : base.lowercased()
    }
}

private struct ChessSceneContainer: UIViewControllerRepresentable {
    @ObservedObject var store: GameStore

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> ChessSceneViewController {
        let controller = ChessSceneViewController()
        controller.onSquareTapped = { square in
            Task { @MainActor in
                store.tap(square: square)
            }
        }
        controller.onSquareHovered = { square in
            Task { @MainActor in
                store.hover(square: square)
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: ChessSceneViewController, context: Context) {
        uiViewController.onSquareTapped = { square in
            Task { @MainActor in
                store.tap(square: square)
            }
        }
        uiViewController.onSquareHovered = { square in
            Task { @MainActor in
                store.hover(square: square)
            }
        }

        let animatedMove: Move?
        if let animation = store.moveAnimation,
           context.coordinator.lastRenderedMoveSequence != animation.sequence {
            animatedMove = animation.move
            context.coordinator.lastRenderedMoveSequence = animation.sequence
        } else {
            animatedMove = nil
        }

        let perspectiveColor: PieceColor
        switch store.mode {
        case .hotSeat:
            perspectiveColor = store.state.turn
        case .localAI:
            perspectiveColor = .white
        case .online:
            perspectiveColor = store.localOnlineColor
        }

        uiViewController.render(
            state: store.state,
            animatedMove: animatedMove,
            selectedSquare: store.selectedSquare,
            legalSquares: store.legalTargetSquares,
            hoveredSquare: store.hoveredSquare,
            perspective: perspectiveColor
        )
    }

    final class Coordinator {
        var lastRenderedMoveSequence = -1
    }
}
