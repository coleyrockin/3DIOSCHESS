import SwiftUI

struct DifficultyPickerView: View {
    @Binding var isPresented: Bool
    @ObservedObject var store: GameStore

    var body: some View {
        NavigationStack {
            ZStack {
                FuturisticBackground()
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Difficulty")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(DesignSystem.textPrimary)

                    VStack(spacing: 12) {
                        ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                            Button(action: {
                                store.setAIDifficulty(difficulty)
                                store.startNewGame(mode: .localAI)
                                isPresented = false
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(difficulty.rawValue)
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundStyle(DesignSystem.textPrimary)
                                    Text(difficulty.description)
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundStyle(DesignSystem.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(DesignSystem.accentPurple.opacity(0.15))
                                .cornerRadius(12)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("AI Difficulty")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
