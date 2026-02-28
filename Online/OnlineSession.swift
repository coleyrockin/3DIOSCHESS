import Foundation
import GameKit
import UIKit

@MainActor
final class OnlineSession: NSObject, ObservableObject {
    enum ConnectionState: String {
        case idle
        case authenticating
        case authenticated
        case findingMatch
        case connected
        case disconnected
        case error
    }

    @Published var state: ConnectionState = .idle
    @Published var statusMessage: String = "Offline"
    @Published var matchmakerViewController: GKMatchmakerViewController?
    @Published var authenticationViewController: UIViewController?

    private(set) var match: GKMatch?

    var onDataReceived: ((Data) -> Void)?
    var onDisconnect: (() -> Void)?

    func authenticateLocalPlayer() {
        state = .authenticating
        statusMessage = "Authenticating Game Center"

        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }

            if let viewController {
                self.authenticationViewController = viewController
                return
            }

            if let error {
                self.state = .error
                self.statusMessage = "Game Center error: \(error.localizedDescription)"
                return
            }

            if GKLocalPlayer.local.isAuthenticated {
                self.state = .authenticated
                self.statusMessage = "Game Center ready"
            } else {
                self.state = .idle
                self.statusMessage = "Game Center not authenticated"
            }
        }
    }

    func findMatch() {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticateLocalPlayer()
            return
        }

        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2

        let controller = GKMatchmakerViewController(matchRequest: request)
        controller?.matchmakerDelegate = self

        state = .findingMatch
        statusMessage = "Looking for a 2-player match"
        matchmakerViewController = controller
    }

    func send(_ data: Data) throws {
        guard let match else {
            throw NSError(domain: "OnlineSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active match"])
        }
        try match.sendData(toAllPlayers: data, with: .reliable)
    }

    func disconnect() {
        match?.disconnect()
        match = nil
        state = .disconnected
        statusMessage = "Disconnected"
        matchmakerViewController = nil
    }
}

extension OnlineSession: GKMatchmakerViewControllerDelegate {
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        state = .idle
        statusMessage = "Matchmaking cancelled"
        matchmakerViewController = nil
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        state = .error
        statusMessage = "Matchmaking failed: \(error.localizedDescription)"
        matchmakerViewController = nil
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        self.match = match
        match.delegate = self
        state = .connected
        statusMessage = "Connected to match"
        matchmakerViewController = nil
    }
}

extension OnlineSession: GKMatchDelegate {
    nonisolated func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        Task { @MainActor [weak self] in
            self?.onDataReceived?(data)
        }
    }

    nonisolated func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if state == .disconnected {
                self.state = .disconnected
                self.statusMessage = "Opponent disconnected"
                self.onDisconnect?()
            }
        }
    }

    nonisolated func match(_ match: GKMatch, didFailWithError error: Error?) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.state = .error
            self.statusMessage = "Match error: \(error?.localizedDescription ?? "Unknown")"
        }
    }
}
