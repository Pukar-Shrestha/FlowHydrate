import SwiftUI

/// A glassmorphism-styled card container used throughout the app.
///
/// Wraps arbitrary content in a frosted-glass card with rounded corners,
/// a subtle border, and a soft shadow. Includes an entrance animation
/// that scales and fades the card in.
struct GlassCard<Content: View>: View {
    /// The content to display inside the card.
    @ViewBuilder var content: () -> Content

    /// Whether the system requests reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Tracks whether the entrance animation has completed.
    @State private var hasAppeared = false

    var body: some View {
        content()
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .scaleEffect(hasAppeared ? 1.0 : 0.95)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .onAppear {
                guard !hasAppeared else { return }
                if reduceMotion {
                    hasAppeared = true
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        hasAppeared = true
                    }
                }
            }
    }
}

/// A view modifier that applies glassmorphism card styling to any view.
///
/// Provides the same frosted-glass appearance as ``GlassCard`` but as a
/// composable modifier, allowing `.glassCard()` to be applied inline.
struct GlassCardModifier: ViewModifier {
    /// Whether the system requests reduced motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Tracks whether the entrance animation has completed.
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .scaleEffect(hasAppeared ? 1.0 : 0.95)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .onAppear {
                guard !hasAppeared else { return }
                if reduceMotion {
                    hasAppeared = true
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        hasAppeared = true
                    }
                }
            }
    }
}

extension View {
    /// Applies glassmorphism card styling to this view.
    ///
    /// Adds a frosted-glass background, subtle border, soft shadow,
    /// and an entrance animation identical to ``GlassCard``.
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}

#Preview("GlassCard — Container") {
    ZStack {
        LinearGradient(
            colors: [.deepNavy, .electricBlue.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Focus Session", systemImage: "timer")
                        .font(.headline)
                    Text("25 minutes remaining")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GlassCard {
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.title)
                        .foregroundStyle(.aqua)
                    VStack(alignment: .leading) {
                        Text("Hydration")
                            .font(.headline)
                        Text("1,200 mL / 2,500 mL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .padding()
    }
}

#Preview("GlassCard — Modifier") {
    ZStack {
        Color.deepNavy.ignoresSafeArea()

        VStack(alignment: .leading, spacing: 8) {
            Text("Using .glassCard() modifier")
                .font(.headline)
            Text("Applied as a ViewModifier")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .padding()
    }
}
