import SwiftUI

// MARK: - GlassmorphismCardModifier

/// Frosted glass card effect with accessibility fallback to solid background
struct GlassmorphismCardModifier: ViewModifier {
    // MARK: - Properties

    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency: Bool

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.cardBackground)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
            }
            .shadow(color: AppColors.shadowColor.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - View Extension

extension View {
    func glassmorphismCard() -> some View {
        modifier(GlassmorphismCardModifier())
    }
}
