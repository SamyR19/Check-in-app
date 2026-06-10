import SwiftUI
import UIKit

// MARK: - Color palette

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

enum Theme {
    /// Warm off-white canvas, like paper.
    static let canvas = Color(hex: 0xF6F4EF)
    /// Near-black ink for text and the check-in button.
    static let ink = Color(hex: 0x17181A)
    /// Soft secondary text.
    static let inkSecondary = Color(hex: 0x8A8D93)
    /// Card surface.
    static let surface = Color.white
    /// Lime accent — active tab pill, map button.
    static let lime = Color(hex: 0xB0E34A)
    static let limeSoft = Color(hex: 0xE4F7BC)
    /// Sky blue — progress + gradients.
    static let sky = Color(hex: 0x4D9FFF)
    static let skySoft = Color(hex: 0xBFE0FF)
    /// Warm coral for streaks and alerts.
    static let coral = Color(hex: 0xFF6B4A)

    static let skyGradient = LinearGradient(
        colors: [Color(hex: 0x9ED2FF), Color(hex: 0x2E8CFF)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0xCDEE82), Color(hex: 0x6FC8FF)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography (rounded everywhere)

extension Font {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func thump() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Shared modifiers

struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.surface)
                    .shadow(color: Theme.ink.opacity(0.05), radius: 12, y: 6)
            )
    }
}

extension View {
    func card(cornerRadius: CGFloat = 24) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
}

/// Press-down spring scale used by every tappable element.
struct SquishyButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Staggered fade-up entrance for list content.
struct AppearStagger: ViewModifier {
    let index: Int
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.06)) {
                    shown = true
                }
            }
    }
}

extension View {
    func appearStagger(_ index: Int) -> some View {
        modifier(AppearStagger(index: index))
    }
}
