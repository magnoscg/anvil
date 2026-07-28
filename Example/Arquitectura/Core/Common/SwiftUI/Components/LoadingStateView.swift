import SwiftUI

// MARK: - LoadingStateView

/// Reusable loading state view for displaying a centered progress indicator.
/// Use this component for consistent loading presentation across the app.
struct LoadingStateView: View {
    // MARK: - Body

    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    LoadingStateView()
}
