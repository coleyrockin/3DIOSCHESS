import SwiftUI

struct OnlineMenuView: View {
    @ObservedObject var store: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Online")
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(DesignSystem.textPrimary)

            Text(store.onlineSession.statusMessage)
                .font(.system(size: DesignSystem.minimumBodyFont, weight: .medium, design: .rounded))
                .foregroundStyle(DesignSystem.textSecondary)

            if store.onlineSession.state == .connected {
                Text("Local color: \(store.localOnlineColor == .white ? "White" : "Black")")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(DesignSystem.neonBlue)
            }

            Button("Authenticate Game Center") {
                store.authenticateGameCenter()
            }
            .buttonStyle(NeonButtonStyle(accent: DesignSystem.accentPurple))

            Button("Find Match") {
                store.findOnlineMatch()
            }
            .buttonStyle(NeonButtonStyle(accent: DesignSystem.neonBlue))

            Button("Disconnect") {
                store.disconnectOnline()
            }
            .disabled(store.onlineSession.state != .connected)
            .buttonStyle(NeonButtonStyle(accent: DesignSystem.glowPink))
        }
        .padding(16)
        .glassPanel(cornerRadius: 20)
    }
}
