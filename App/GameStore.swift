import Combine
import Foundation
import AudioToolbox
import UIKit

struct MoveAnimation: Equatable {
    let move: Move
    let sequence: Int
}

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var state: GameState
    @Published private(set) var mode: GameMode
    @Published var selectedSquare: Square?
    @Published var legalTargetSquares: [Square]
    @Published var hoveredSquare: Square?
    @Published var moveAnimation: MoveAnimation?
    @Published var transientMessage: String?
    @Published var errorMessage: String?

    let onlineSession: OnlineSession
    let onlineCoordinator: OnlineGameCoordinator

    private var aiDifficulty: AIDifficulty = .medium
    private var history: [GameState] = []
    private var moveSequence = 0
    private var aiThinking = false
    private var cancellables: Set<AnyCancellable> = []

    private(set) var localOnlineColor: PieceColor = .white

    init(
        initialState: GameState = Rules.initialState(),
        mode: GameMode = .hotSeat,
        onlineSession: OnlineSession? = nil
    ) {
        let resolvedSession = onlineSession ?? OnlineSession()

        self.state = initialState
        self.mode = mode
        self.selectedSquare = nil
        self.legalTargetSquares = []
        self.hoveredSquare = nil
        self.moveAnimation = nil
        self.onlineSession = resolvedSession
        self.onlineCoordinator = OnlineGameCoordinator(session: resolvedSession)

        onlineCoordinator.onRemoteMove = { [weak self] move in
            self?.receiveRemoteMove(move)
        }

        resolvedSession.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] sessionState in
                guard let self else { return }
                if sessionState == .connected {
                    self.onlineCoordinator.refreshColorAssignment()
                    self.localOnlineColor = self.onlineCoordinator.localColor
                    self.startNewGame(mode: .online)
                    self.transientMessage = self.localOnlineColor == .white ? "You are White" : "You are Black"
                }
            }
            .store(in: &cancellables)

        onlineCoordinator.$lastError
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                guard let self, let value else { return }
                self.errorMessage = value
            }
            .store(in: &cancellables)

        // Forward all OnlineSession published-property changes so that views
        // observing GameStore (e.g. RootView sheets, OnlineMenuView) re-render
        // whenever authenticationViewController, matchmakerViewController,
        // statusMessage, or state change on the session.
        resolvedSession.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var isLocalPlayersTurn: Bool {
        switch mode {
        case .online:
            return state.turn == localOnlineColor
        case .hotSeat, .localAI:
            return true
        }
    }

    func startNewGame(mode: GameMode) {
        self.mode = mode
        state = Rules.initialState()
        history.removeAll()
        selectedSquare = nil
        legalTargetSquares = []
        hoveredSquare = nil
        moveAnimation = nil
        aiThinking = false
        PieceNodeFactory.clearCache()

        if mode == .localAI {
            scheduleAIMoveIfNeeded()
        }
    }

    func tap(square: Square) {
        guard state.status == .ongoing || state.status == .check else {
            return
        }
        guard isLocalPlayersTurn else {
            transientMessage = "Waiting for opponent"
            return
        }

        if let selectedSquare {
            if selectedSquare == square {
                deselect()
                return
            }

            let legalMoves = Rules.legalMoves(from: selectedSquare, in: state)
            if let chosenMove = preferredMove(to: square, from: legalMoves) {
                commit(move: chosenMove, sendOnline: mode == .online)
                return
            }
        }

        guard let piece = state.board.piece(at: square), piece.color == state.turn else {
            deselect()
            return
        }

        playTapSound()
        selectedSquare = square
        legalTargetSquares = Array(Set(Rules.legalMoves(from: square, in: state).map(\.to))).sorted()
    }

    func hover(square: Square?) {
        hoveredSquare = square
    }

    func deselect() {
        selectedSquare = nil
        legalTargetSquares = []
    }

    func undo() {
        guard mode != .online else {
            transientMessage = "Undo unavailable online"
            return
        }

        guard !history.isEmpty else {
            return
        }

        if mode == .localAI {
            _ = history.popLast()
            if let prior = history.popLast() {
                state = prior
            } else {
                state = Rules.initialState()
            }
        } else if let prior = history.popLast() {
            state = prior
        }

        selectedSquare = nil
        legalTargetSquares = []
        hoveredSquare = nil
        moveAnimation = nil
        aiThinking = false
    }

    func resignCurrentPlayer() {
        guard state.status == .ongoing || state.status == .check else { return }
        state.status = .resigned
        state.winner = state.turn.opposite
        state.checkedKing = nil
        selectedSquare = nil
        legalTargetSquares = []
    }

    func saveGame() {
        do {
            try SaveManager.shared.save(state: state, history: history, mode: mode)
            transientMessage = "Game saved"
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    func loadGame() {
        do {
            let saved = try SaveManager.shared.load()
            state = saved.state
            history = saved.history
            mode = saved.mode
            selectedSquare = nil
            legalTargetSquares = []
            hoveredSquare = nil
            moveAnimation = nil
            transientMessage = "Loaded saved game"
        } catch {
            errorMessage = "Load failed: \(error.localizedDescription)"
        }
    }

    func hasSave() -> Bool {
        SaveManager.shared.hasSave()
    }

    func authenticateGameCenter() {
        onlineSession.authenticateLocalPlayer()
    }

    func findOnlineMatch() {
        mode = .online
        onlineCoordinator.startMatchmaking()
    }

    func disconnectOnline() {
        onlineSession.disconnect()
        if mode == .online {
            startNewGame(mode: .hotSeat)
        }
    }

    private func preferredMove(to destination: Square, from legalMoves: [Move]) -> Move? {
        let candidates = legalMoves.filter { $0.to == destination }
        guard !candidates.isEmpty else { return nil }

        if let nonPromotion = candidates.first(where: { $0.promotion == nil }) {
            return nonPromotion
        }
        if let queenPromotion = candidates.first(where: { $0.promotion == .queen }) {
            return queenPromotion
        }
        return candidates.first
    }

    private func commit(move: Move, sendOnline: Bool) {
        let wasCapture = move.isEnPassant || state.board.piece(at: move.to) != nil

        var updated = state
        guard Rules.makeMove(move, in: &updated) else {
            errorMessage = "Illegal move"
            return
        }

        history.append(state)
        state = updated
        moveSequence += 1
        moveAnimation = MoveAnimation(move: move, sequence: moveSequence)

        selectedSquare = nil
        legalTargetSquares = []
        hoveredSquare = nil

        provideFeedback(capture: wasCapture)

        if mode == .online, sendOnline {
            onlineCoordinator.send(move: move)
        }

        if mode == .localAI {
            scheduleAIMoveIfNeeded()
        }
    }

    private func receiveRemoteMove(_ move: Move) {
        guard mode == .online else {
            return
        }
        commit(move: move, sendOnline: false)
    }

    func setAIDifficulty(_ difficulty: AIDifficulty) {
        aiDifficulty = difficulty
    }

    private func scheduleAIMoveIfNeeded() {
        guard mode == .localAI,
              state.turn == .black,
              (state.status == .ongoing || state.status == .check),
              !aiThinking else {
            return
        }

        let snapshot = state
        let aiMaxDepth = aiDifficulty.depth
        aiThinking = true

        DispatchQueue.global(qos: .userInitiated).async {
            let move = ChessAI(maxDepth: aiMaxDepth).bestMove(in: snapshot)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                defer { self.aiThinking = false }

                guard self.state == snapshot else { return }
                guard let move else { return }
                self.commit(move: move, sendOnline: false)
            }
        }
    }

    private func playTapSound() {
        AudioServicesPlaySystemSound(1105)
    }

    private func provideFeedback(capture: Bool) {
        let soundID: SystemSoundID = capture ? 1151 : 1104
        AudioServicesPlaySystemSound(soundID)

        guard UIDevice.current.userInterfaceIdiom == .phone else {
            return
        }
        let generator = UIImpactFeedbackGenerator(style: capture ? .medium : .light)
        generator.prepare()
        generator.impactOccurred()
    }
}
