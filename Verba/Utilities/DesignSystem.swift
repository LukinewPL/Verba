import SwiftUI

enum DesignSystem {
    enum Colors {
        static let background = Color.deepNavy
        static let primary = Color.glassCyan
        static let secondary = Color(red: 0.1, green: 0.3, blue: 0.5)
        static let surface = Color.white.opacity(0.12)
        static let glassEffect = Color.white.opacity(0.15)
        
        static let success = Color.green
        static let error = Color.red
        static let secondaryText = Color.white.opacity(0.65)
        
        static let luxuryGradient = LinearGradient(
            colors: [Color(red: 0.1, green: 0.2, blue: 0.5), Color.deepNavy],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
                        colors: [.white.opacity(0.35), .clear, .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 10)
    }
    
    func vibrantTitle() -> some View {
        self.font(.system(size: 32, weight: .medium, design: .default))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: 2)
    }
}
