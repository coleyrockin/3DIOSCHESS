import Foundation
import GameKit

@MainActor
final class OnlineGameCoordinator: ObservableObject {
    @Published var localColor: PieceColor = .white
    @Published var lastError: String?

    private let session: OnlineSession
    private let messenger: MatchMessenger

    var onRemoteMove: ((Move) -> Void)?

    init(session: OnlineSession, messenger: MatchMessenger = MatchMessenger()) {
        self.session = session
        self.messenger = messenger

        session.onDataReceived = { [weak self] data in
            self?.handleIncoming(data: data)
        }

        session.onDisconnect = { [weak self] in
            self?.lastError = "Opponent disconnected. Returning to menu."
        }
    }

    func startMatchmaking() {
        session.findMatch()
    }

    func refreshColorAssignment() {
        guard let match = session.match else {
            localColor = .white
            return
        }

        let localID = GKLocalPlayer.local.gamePlayerID
        let opponentID = match.players.first?.gamePlayerID ?? ""
        localColor = localID < opponentID ? .white : .black
    }

    func send(move: Move) {
        do {
            let data = try messenger.encode(move: move)
            try session.send(data)
        } catch {
            lastError = "Failed to send move: \(error.localizedDescription)"
        }
    }

    private func handleIncoming(data: Data) {
        do {
            let move = try messenger.decodeMove(from: data)
            onRemoteMove?(move)
        } catch {
            lastError = "Invalid move payload received."
        }
    }
}
