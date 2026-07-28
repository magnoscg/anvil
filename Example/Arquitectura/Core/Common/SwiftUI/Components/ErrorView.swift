import SwiftUI

// MARK: - ErrorStateView

/// Reusable error state view for displaying error information with optional retry action.
/// Use this component for consistent error presentation across the app.
struct ErrorView: View {
    // MARK: - Properties

    let error: ErrorDecorator
    let onRetry: (() -> Void)?

    // MARK: - Init

    init(error: ErrorDecorator, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.lg) {
            StatusIcon.error.image
                .font(.largeTitle)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .foregroundStyle(AppColors.error)

            Text(error.title)
                .font(AppTypography.title2.font)

            Text(error.message)
                .font(AppTypography.body.font)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            if error.isRetryable, let onRetry {
                Button(String(localized: "error.button.retry")) {
                    onRetry()
                }
                .primaryButtonStyle()
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Retryable Error") {
    ErrorView(error: .generic) {
        print("Retry tapped")
    }
}

#Preview("Non-Retryable Error") {
    ErrorView(error: .notFound)
}
