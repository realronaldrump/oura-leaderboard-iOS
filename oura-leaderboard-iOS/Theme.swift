import SwiftUI

// MARK: - App Theme

struct Theme {
    // MARK: - Background Colors
    static let bgBase = Color(hex: "0C0C0C")
    static let bgRaised = Color(hex: "141414")
    static let bgElevated = Color(hex: "1C1C1C")
    static let bgHover = Color(hex: "242424")
    
    // MARK: - Border Colors
    static let borderSubtle = Color(hex: "222222")
    static let borderDefault = Color(hex: "333333")
    static let borderStrong = Color(hex: "444444")
    
    // MARK: - Accent Colors
    static let accent = Color(hex: "00C896")
    static let accentCyan = Color(hex: "00D4FF")
    static let accentPurple = Color(hex: "A855F7")
    static let accentGreen = Color(hex: "10B981")
    static let accentOrange = Color(hex: "F59E0B")
    static let accentRose = Color(hex: "F43F5E")
    
    // MARK: - Metric Colors
    static let metricGreen = Color(hex: "34D399")   // Readiness
    static let metricBlue = Color(hex: "60A5FA")    // Sleep
    static let metricAmber = Color(hex: "FBBF24")   // Activity
    static let metricRed = Color(hex: "F87171")     // Heart Rate
    static let metricPurple = Color(hex: "8B5CF6")  // HRV
    static let metricCyan = Color(hex: "06B6D4")    // SpO2
    
    // Specific metric colors matching desktop
    static let readinessColor = Color(hex: "10B981")
    static let sleepColor = Color(hex: "3B82F6")
    static let activityColor = Color(hex: "F59E0B")
    static let hrColor = Color(hex: "EF4444")
    static let hrvColor = Color(hex: "A855F7")
    
    // MARK: - Text Colors
    static let textPrimary = Color(hex: "FAFAFA")
    static let textSecondary = Color(hex: "A0A0A0")
    static let textMuted = Color(hex: "666666")
    static let textDim = Color(hex: "525252")
    
    // MARK: - Gradients
    static let gradientCyanPurple = LinearGradient(
        colors: [accentCyan, accentPurple],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let gradientMesh = LinearGradient(
        colors: [
            Color(hex: "00D4FF").opacity(0.12),
            Color(hex: "A855F7").opacity(0.08),
            Color(hex: "10B981").opacity(0.06)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Sleep Stage Colors
    static let deepSleep = Color(hex: "1E40AF")
    static let lightSleep = Color(hex: "3B82F6")
    static let remSleep = Color(hex: "8B5CF6")
    static let awake = Color(hex: "6B7280")
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct GlassCard: ViewModifier {
    var padding: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.bgRaised)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.borderSubtle, lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(padding: CGFloat = 16) -> some View {
        modifier(GlassCard(padding: padding))
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Theme.textPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.borderDefault, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Gradient Text

struct GradientText: View {
    let text: String
    var font: Font = .system(size: 32, weight: .bold)
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(Theme.gradientCyanPurple)
    }
}
