import SwiftUI

extension Color {
    public static let emojiGold = Color(red: 1.0, green: 0.82, blue: 0.15)
    public static let glassBg = Color.black.opacity(0.45)
    public static let glassBorder = Color.white.opacity(0.18)
    public static let trackingGreen = Color(red: 0.18, green: 0.80, blue: 0.44)
    public static let textMuted = Color(white: 0.75)
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.40))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.20), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

extension View {
    public func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
