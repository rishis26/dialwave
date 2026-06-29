import SwiftUI

/// Reusable SwiftUI view modifiers for DialWave's design system.
extension View {

    // MARK: - Card Style

    /// Applies the standard DialWave card appearance: rounded corners, background, and shadow.
    ///
    /// - Returns: A view wrapped in a card container.
    func dialwaveCard() -> some View {
        self
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    // MARK: - Shimmer Loading Effect

    /// Applies a shimmering loading skeleton animation.
    ///
    /// Useful for placeholder content while data is loading.
    ///
    /// - Returns: A view with a horizontal shimmer gradient animation.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    // MARK: - First Appear

    /// Calls a closure only the first time the view appears, not on subsequent reappearances.
    ///
    /// - Parameter perform: The closure to execute once.
    /// - Returns: A view that triggers the action on its first appearance.
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(FirstAppearModifier(action: action))
    }

    // MARK: - Conditional Modifier

    /// Applies a modifier only when the given condition is true.
    ///
    /// - Parameters:
    ///   - condition: Whether to apply the modifier.
    ///   - modifier: The modifier to apply conditionally.
    /// - Returns: The view, optionally modified.
    @ViewBuilder
    func conditionalModifier<M: ViewModifier>(_ condition: Bool, modifier: M) -> some View {
        if condition {
            self.modifier(modifier)
        } else {
            self
        }
    }
}

// MARK: - Shimmer Modifier

/// A `ViewModifier` that overlays an animated gradient shimmer effect.
private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1.0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.15),
                        .clear,
                    ],
                    startPoint: .init(x: phase - 0.5, y: 0.5),
                    endPoint: .init(x: phase + 0.5, y: 0.5)
                )
                .blendMode(.screen)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 2.0
                }
            }
    }
}

// MARK: - First Appear Modifier

/// A `ViewModifier` that fires an action exactly once on the view's first appearance.
private struct FirstAppearModifier: ViewModifier {
    let action: () -> Void
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                action()
            }
    }
}
