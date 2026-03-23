import SwiftUI

enum DesignSystem {
    enum Colors {
        static let background = Color.deepNavy
        static let primary = Color.glassCyan
        static let surface = Color.white.opacity(0.1)
        static let glassBack = Color.glassBack
        
        static let success = Color.green
        static let error = Color.red
        static let secondaryText = Color.white.opacity(0.6)
    }
    
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }
    
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
    }
    
    enum Animation {
        static let standard = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.75)
        static let slow = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
    }
}

extension View {
    func standardGlassEffect() -> some View {
        self.modifier(GlassEffect())
    }
}
