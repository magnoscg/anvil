import SwiftUI

// MARK: - StatusColor + SwiftUI Bridge

extension ArchitectureItemDecorator.StatusColor {
    /// Converts semantic status color to SwiftUI Color for UI rendering
    var uiColor: Color {
        switch self {
        case .implemented:
            AppColors.success
        case .pending:
            AppColors.warning
        }
    }
}
