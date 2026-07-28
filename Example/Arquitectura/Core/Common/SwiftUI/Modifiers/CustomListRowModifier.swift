import SwiftUI

// MARK: - Custom List Row Modifier

/// ViewModifier extension for configuring List row appearance.
/// Removes separators, clears background, and allows custom insets.
extension View {
    /// Configures a List row with custom insets, hidden separator, and clear background.
    /// - Parameters:
    ///   - top: Top inset (default: 0)
    ///   - leading: Leading inset (default: 0)
    ///   - bottom: Bottom inset (default: 0)
    ///   - trailing: Trailing inset (default: 0)
    /// - Returns: Modified view configured for List row display
    func customListRow(top: CGFloat = 0,
                       leading: CGFloat = 0,
                       bottom: CGFloat = 0,
                       trailing: CGFloat = 0) -> some View {
        self
            .listRowInsets(.init(top: top, leading: leading, bottom: bottom, trailing: trailing))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
