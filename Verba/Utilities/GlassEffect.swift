import SwiftUI

struct GlassEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.regularMaterial)
            .environment(\.colorScheme, .dark)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}
struct PressAnimation: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.interactiveSpring(), value: configuration.isPressed)
    }
}

extension View {
    func glassEffect() -> some View { self.modifier(GlassEffect()) }
    func pressAnimation() -> some View { self.buttonStyle(PressAnimation()) }

    func glassPanel(
        cornerRadius: CGFloat = 18,
        edgeHighlight: Color = Color.glassCyan.opacity(0.16),
        gradientTopOpacity: Double = 0.1,
        gradientBottomOpacity: Double = 0.04,
        borderOpacity: Double = 0.14,
        shadowOpacity: Double = 0.22,
        shadowRadius: CGFloat = 14,
        shadowY: CGFloat = 8
    ) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(gradientTopOpacity), Color.white.opacity(gradientBottomOpacity)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(edgeHighlight, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(borderOpacity), lineWidth: 1)
                )
                .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: shadowY)
        )
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding().glassEffect().scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(bounce: 0.3), value: configuration.isPressed)
    }
}
