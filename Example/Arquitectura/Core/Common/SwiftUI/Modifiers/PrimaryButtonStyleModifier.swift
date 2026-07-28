import SwiftUI

// MARK: - PrimaryButtonStyleModifier

struct PrimaryButtonStyleModifier: ViewModifier {
    // MARK: - Properties

    let isEnabled: Bool

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(AppColors.surface)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(LinearGradient(colors: isEnabled ? [AppColors.gradientStart, AppColors.gradientEnd] :
                    [AppColors.textSecondary],
                startPoint: .leading,
                endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: AppColors.gradientStart.opacity(isEnabled ? 0.3 : 0), radius: 8, x: 0, y: 4)
    }
}

// MARK: - View Extension

extension View {
    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        modifier(PrimaryButtonStyleModifier(isEnabled: isEnabled))
    }
}
