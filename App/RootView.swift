import SwiftUI
import UIKit

struct RootView: View {
    @StateObject private var store = GameStore()
    @State private var showPhoneActions = false

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        ZStack {
            FuturisticBackground()

            Group {
                if isPad {
                    iPadLayout
                } else {
                    iPhoneLayout
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(DesignSystem.neonBlue)
        .sheet(isPresented: authenticationSheetBinding) {
            if let controller = store.onlineSession.authenticationViewController {
                ExistingViewControllerHost(controller: controller)
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: matchmakerSheetBinding) {
            if let controller = store.onlineSession.matchmakerViewController {
                ExistingViewControllerHost(controller: controller)
                    .ignoresSafeArea()
            }
        }
        .alert("Chess3D", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {
                store.errorMessage = nil
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .safeAreaInset(edge: .bottom) {
            if let message = store.transientMessage {
                Text(message)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(DesignSystem.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassPanel(cornerRadius: 18)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
        }
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            GeometryReader { geometry in
                let spacing = max(14, geometry.size.height * 0.024)
                let horizontalPadding = max(16, geometry.size.width * 0.06)

                ScrollView {
                    VStack(alignment: .leading, spacing: spacing) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Chess3D")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(DesignSystem.textPrimary)

                            Text("Futuristic 3D chess with smooth, readable controls")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(DesignSystem.textSecondary)
                        }

                        GameHUDView(store: store)
                        OfflineMenuView(store: store)
                        OnlineMenuView(store: store)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, spacing)
                }
            }
            .navigationTitle("Controls")
        } detail: {
            GameContainerView(store: store, showHUDBelowBoard: false)
                .navigationTitle("Board")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("New") {
                            store.startNewGame(mode: .hotSeat)
                        }
                        .keyboardShortcut("n", modifiers: .command)

                        Button("Undo") {
                            store.undo()
                        }
                        .keyboardShortcut("z", modifiers: .command)

                        Button("Deselect") {
                            store.deselect()
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var iPhoneLayout: some View {
        NavigationStack {
            GameContainerView(store: store, showHUDBelowBoard: true)
                .navigationTitle("Chess3D")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("New") {
                            store.startNewGame(mode: .hotSeat)
                        }
                        .keyboardShortcut("n", modifiers: .command)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Actions") {
                            showPhoneActions = true
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Undo") {
                            store.undo()
                        }
                        .keyboardShortcut("z", modifiers: .command)
                    }
                }
                .sheet(isPresented: $showPhoneActions) {
                    NavigationStack {
                        ZStack {
                            FuturisticBackground()

                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    OfflineMenuView(store: store)
                                    OnlineMenuView(store: store)
                                }
                                .padding(16)
                            }
                        }
                        .navigationTitle("Actions")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    showPhoneActions = false
                                }
                            }
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    store.errorMessage = nil
                }
            }
        )
    }

    private var authenticationSheetBinding: Binding<Bool> {
        Binding(
            get: { store.onlineSession.authenticationViewController != nil },
            set: { newValue in
                if !newValue {
                    store.onlineSession.authenticationViewController = nil
                }
            }
        )
    }

    private var matchmakerSheetBinding: Binding<Bool> {
        Binding(
            get: { store.onlineSession.matchmakerViewController != nil },
            set: { newValue in
                if !newValue {
                    store.onlineSession.matchmakerViewController = nil
                }
            }
        )
    }
}

struct ExistingViewControllerHost: UIViewControllerRepresentable {
    let controller: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
