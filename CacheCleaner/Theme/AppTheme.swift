import SwiftUI

// MARK: - Color Palette

enum AppTheme {
    
    // MARK: Category Colors
    
    enum Category {
        static let general = Color.blue
        static let xcode = Color.orange
        static let development = Color.green
        static let destructive = Color.red
    }
    
    // MARK: Category Gradients
    
    enum Gradient {
        static let general = LinearGradient(
            colors: [Color(hex: 0x007AFF), Color(hex: 0x5856D6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let xcode = LinearGradient(
            colors: [Color(hex: 0xFF9500), Color(hex: 0xFF3B30)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let development = LinearGradient(
            colors: [Color(hex: 0x34C759), Color(hex: 0x30B050)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        // Ring gauge now uses category colors directly (segments)
    }
    
    // MARK: Spacing
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: Corner Radius
    
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
    
    // MARK: Shadows
    
    static let cardShadow = ShadowStyle.drop(
        color: .black.opacity(0.08),
        radius: 12,
        x: 0,
        y: 4
    )
    
    // MARK: Ring Gauge
    
    enum Gauge {
        static let size: CGFloat = 160
        static let lineWidth: CGFloat = 14
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    var accentColor: Color = .blue
    var showAccentBar: Bool = true
    
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            }
            .overlay(alignment: .leading) {
                if showAccentBar {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor.gradient)
                        .frame(width: 4)
                        .padding(.vertical, AppTheme.Spacing.sm)
                }
            }
    }
}

extension View {
    func glassCard(accent: Color = .blue, showBar: Bool = true) -> some View {
        modifier(GlassCardModifier(accentColor: accent, showAccentBar: showBar))
    }
}

// MARK: - Hover Highlight Modifier

struct HoverHighlightModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                    .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

extension View {
    func hoverHighlight() -> some View {
        modifier(HoverHighlightModifier())
    }
}
