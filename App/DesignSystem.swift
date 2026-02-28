import SwiftUI
import UIKit

enum DesignSystem {
    static let background = Color(uiColor: UIColor(hex: 0x05070A))
    static let neonBlue = Color(uiColor: UIColor(hex: 0x00D4FF))
    static let accentPurple = Color(uiColor: UIColor(hex: 0x7B61FF))
    static let glowPink = Color(uiColor: UIColor(hex: 0xFF4FD8))
    static let gold = Color(uiColor: UIColor(hex: 0xC6A15B))

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.82)

    static let panelFillOpacity: Double = 0.18
    static let panelStrokeOpacity: Double = 0.22
    static let panelCornerRadius: CGFloat = 20
    static let minimumBodyFont: CGFloat = 16
    static let buttonHeight: CGFloat = 56
}

struct FuturisticBackground: View {
    var body: some View {
        ZStack {
            DesignSystem.background

            LinearGradient(
                colors: [
                    DesignSystem.accentPurple.opacity(0.18),
                    .clear,
                    DesignSystem.neonBlue.opacity(0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [DesignSystem.neonBlue.opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )

            RadialGradient(
                colors: [DesignSystem.glowPink.opacity(0.12), .clear],
                center: .bottomLeading,
                startRadius: 24,
                endRadius: 460
            )
        }
        .ignoresSafeArea()
    }
}

struct UltraThinDarkMaterialView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
    }
}

struct GlassPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = DesignSystem.panelCornerRadius

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    UltraThinDarkMaterialView()
                    Color.white.opacity(DesignSystem.panelFillOpacity)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(DesignSystem.panelStrokeOpacity), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = DesignSystem.panelCornerRadius) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius))
    }
}

struct NeonButtonStyle: ButtonStyle {
    var accent: Color = DesignSystem.neonBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(DesignSystem.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: DesignSystem.buttonHeight)
            .background {
                ZStack {
                    UltraThinDarkMaterialView()
                    LinearGradient(
                        colors: [
                            accent.opacity(configuration.isPressed ? 0.18 : 0.12),
                            Color.white.opacity(configuration.isPressed ? 0.12 : 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accent.opacity(configuration.isPressed ? 0.75 : 0.46), lineWidth: 1.2)
            }
            .shadow(
                color: accent.opacity(configuration.isPressed ? 0.32 : 0.24),
                radius: configuration.isPressed ? 7 : 14,
                x: 0,
                y: configuration.isPressed ? 3 : 7
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
