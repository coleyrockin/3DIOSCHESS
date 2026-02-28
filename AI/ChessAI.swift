import Foundation

final class ChessAI {
    let maxDepth: Int

    init(maxDepth: Int = 2) {
        self.maxDepth = max(1, maxDepth)
    }

    func bestMove(in state: GameState) -> Move? {
        let legalMoves = Rules.allLegalMoves(in: state)
        guard !legalMoves.isEmpty else {
            return nil
        }

        let maximizingColor = state.turn
        var bestScore = Int.min
        var bestMove: Move?
        var alpha = Int.min / 2
        let beta = Int.max / 2

        for move in legalMoves {
            var next = state
            guard Rules.makeMove(move, in: &next) else {
                continue
            }

            let score = minimax(
                state: next,
                depth: maxDepth - 1,
                maximizingColor: maximizingColor,
                alpha: alpha,
                beta: beta
            )

            if score > bestScore {
                bestScore = score
                bestMove = move
            }
            alpha = max(alpha, score)
        }

        return bestMove
    }

    private func minimax(
        state: GameState,
        depth: Int,
        maximizingColor: PieceColor,
        alpha: Int,
        beta: Int
    ) -> Int {
        if depth == 0 || state.status == .checkmate || state.status == .stalemate {
            return Evaluator.evaluate(state, perspective: maximizingColor)
        }

        let legalMoves = Rules.allLegalMoves(in: state)
        if legalMoves.isEmpty {
            return Evaluator.evaluate(state, perspective: maximizingColor)
        }

        var alpha = alpha
        var beta = beta

        if state.turn == maximizingColor {
            var best = Int.min
            for move in legalMoves {
                var next = state
                guard Rules.makeMove(move, in: &next) else { continue }
                let score = minimax(state: next, depth: depth - 1, maximizingColor: maximizingColor, alpha: alpha, beta: beta)
                best = max(best, score)
                alpha = max(alpha, score)
                if beta <= alpha {
                    break
                }
            }
            return best
        }

        var best = Int.max
        for move in legalMoves {
            var next = state
            guard Rules.makeMove(move, in: &next) else { continue }
            let score = minimax(state: next, depth: depth - 1, maximizingColor: maximizingColor, alpha: alpha, beta: beta)
            best = min(best, score)
            beta = min(beta, score)
            if beta <= alpha {
                break
            }
        }
        return best
    }
}
