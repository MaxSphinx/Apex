import SwiftUI
import AppKit

public extension Color {
    // Neon Cyber & Apple Silicon Accents
    static let apexCyan = Color(red: 0.0, green: 0.92, blue: 1.0)
    static let apexPurple = Color(red: 0.65, green: 0.40, blue: 1.0)
    static let apexEmerald = Color(red: 0.0, green: 0.90, blue: 0.55)
    static let apexCoral = Color(red: 1.0, green: 0.35, blue: 0.45)
    static let apexAmber = Color(red: 1.0, green: 0.70, blue: 0.20)
    
    // Luxury Obsidian Dark Palette
    static let apexWindowBackground = Color(red: 0.07, green: 0.08, blue: 0.11)
    static let apexCard = Color(red: 0.13, green: 0.14, blue: 0.18).opacity(0.72)
    static let apexCardHover = Color(red: 0.17, green: 0.19, blue: 0.24).opacity(0.85)
    static let apexBorder = Color.white.opacity(0.10)
    static let apexCardBorder = Color.white.opacity(0.10)
    static let apexCardBorderHighlight = Color.white.opacity(0.18)
    
    // Refined Typography Colors
    static let apexTextPrimary = Color(white: 0.96)
    static let apexTextSecondary = Color(white: 0.65)
    static let apexTextTertiary = Color(white: 0.42)
}

public struct LuxuryGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14
    var isHovered: Bool = false
    var accentBorder: Color? = nil
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isHovered ? Color.apexCardHover : Color.apexCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        accentBorder != nil ?
                            LinearGradient(
                                colors: [accentBorder!.opacity(0.6), accentBorder!.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.16), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

public extension View {
    func luxuryGlass(cornerRadius: CGFloat = 14, isHovered: Bool = false, accentBorder: Color? = nil) -> some View {
        self.modifier(LuxuryGlassCardModifier(cornerRadius: cornerRadius, isHovered: isHovered, accentBorder: accentBorder))
    }
    
    // Backwards compatibility alias
    func glassCard(cornerRadius: CGFloat = 14, borderColor: Color = Color.apexCardBorder) -> some View {
        self.luxuryGlass(cornerRadius: cornerRadius, accentBorder: borderColor == Color.apexCardBorder ? nil : borderColor)
    }
}
