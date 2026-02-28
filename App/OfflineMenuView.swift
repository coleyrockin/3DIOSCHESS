import SwiftUI

struct OfflineMenuView: View {
    @ObservedObject var store: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Offline")
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(DesignSystem.textPrimary)

            Button("New Hot-Seat") {
                store.startNewGame(mode: .hotSeat)
            }
            .keyboardShortcut("n", modifiers: .command)
            .buttonStyle(NeonButtonStyle(accent: DesignSystem.neonBlue))

            Button("New vs Local AI") {
                store.startNewGame(mode: .localAI)
            }
            .buttonStyle(NeonButtonStyle(accent: DesignSystem.accentPurple))

            Button("Undo") {
                store.undo()
            }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(store.mode == .online)
            .buttonStyle(NeonButtonStyle(accent: DesignSystem.neonBlue))

            Button("Deselect") {
                store.deselect()
            }
            .keyboardShortcut(.cancelAction)
            .buttonStyle(NeonButtonStyle(accent: DesignSystem.accentPurple))

            Button("Resign") {
                store.resignCurrentPlayer()
            }
            .buttonStyle(NeonButtonStyle(accent: DesignSystem.glowPink))

            Button("Save") {
                store.saveGame()
            }
            .buttonStyle(NeonButtonStyle(accent: DesignSystem.gold))

            Button("Load") {
                store.loadGame()
            }
            .disabled(!store.hasSave())
            .buttonStyle(NeonButtonStyle(accent: DesignSystem.gold))
        }
        .padding(16)
        .glassPanel(cornerRadius: 20)
    }
}
