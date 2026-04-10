import SwiftUI

enum DesignSystem {
    enum Colors {
        static let background = Color(red: 0.02, green: 0.13, blue: 0.16)
        static let primary = Color.glassTeal
        static let secondary = Color.glassSky
        static let surface = Color.white.opacity(0.12)
        static let glassEffect = Color.white.opacity(0.18)

        static let success = Color.glassMint
        static let error = Color(red: 0.95, green: 0.56, blue: 0.45)
        static let secondaryText = Color(red: 0.90, green: 0.98, blue: 0.96).opacity(0.82)
        
        static let luxuryGradient = LinearGradient(
            colors: [Color.glassMint, Color.glassTeal, Color.glassSky, Color.glassPearl],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Feedback {
        static let successGradient = LinearGradient(
            colors: [Color.green.opacity(0.55), Color.green.opacity(0.32)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let failureGradient = LinearGradient(
            colors: [Color.red.opacity(0.6), Color.red.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static func gradient(isSuccess: Bool) -> LinearGradient {
            isSuccess ? successGradient : failureGradient
        }
    }
    
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 36
        static let xxLarge: CGFloat = 48
    }
    
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 14
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 30
    }
    
    enum Animation {
        static let fast = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.7)
        static let standard = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let slow = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.9)
    }
}

extension View {
    func premiumGlass(cornerRadius: CGFloat = DesignSystem.CornerRadius.large) -> some View {
        self
            .padding()
            .background(.ultraThinMaterial)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(LinearGradient(
                        colors: [.white.opacity(0.7), Color.glassMint.opacity(0.34), Color.glassSky.opacity(0.22), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1.2)
            )
            .shadow(color: Color.glassShadow.opacity(0.28), radius: 15, x: 0, y: 10)
    }
    
    func vibrantTitle() -> some View {
        self.font(.system(size: 32, weight: .medium, design: .default))
            .foregroundColor(Color.glassPearl)
            .shadow(color: Color.glassShadow.opacity(0.3), radius: 2)
    }
}
