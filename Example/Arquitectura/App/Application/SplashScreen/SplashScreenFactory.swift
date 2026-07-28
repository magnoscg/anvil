import SwiftUI
import UIKit

// MARK: - SplashScreenFactory

/// Factory for creating SplashScreen components with proper dependency injection
@MainActor
enum SplashScreenFactory {
    // MARK: - Public Methods

    /// Creates a configured SplashScreenView
    /// - Parameter onFinished: Callback invoked when the splash animation completes
    /// - Returns: A fully configured SplashScreenView
    static func makeView(onFinished: @escaping @MainActor () -> Void) -> SplashScreenView {
        let viewModel = SplashScreenViewModel(reduceMotion: UIAccessibility.isReduceMotionEnabled,
                                              onFinished: onFinished)
        return SplashScreenView(viewModel: viewModel)
    }
}
