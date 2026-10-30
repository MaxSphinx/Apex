import SwiftUI

public extension Color {
    static let apexCyan = Color(red: 0.0, green: 0.95, blue: 1.0)
    static let apexPurple = Color(red: 0.55, green: 0.35, blue: 1.0)
    static let apexEmerald = Color(red: 0.1, green: 0.85, blue: 0.5)
    static let apexCoral = Color(red: 1.0, green: 0.4, blue: 0.4)
    static let apexCardBackground = Color.black.opacity(0.3)
    static let apexBorder = Color.white.opacity(0.12)
}

public struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14
    var borderColor: Color = Color.apexBorder
    
    public func body(content: Content) -> some View {
        content
            .background(Color.apexCardBackground)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}

public extension View {
    func glassCard(cornerRadius: CGFloat = 14, borderColor: Color = Color.apexBorder) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, borderColor: borderColor))
    }
}
