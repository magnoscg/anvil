import SwiftUI

// MARK: - AppLaunchState

/// App launch state machine
enum AppLaunchState: Equatable {
    case splash
    case ready
}

// MARK: - ArquitecturaApp

/// Composition root: creates app-lifetime dependencies and the app-wide launch state.
/// Each window gets its own `AppRootView`, which owns that window's navigation.
@main
struct ArquitecturaApp: App {
    // MARK: - Properties

    @State
    private var launchState: AppLaunchState = .splash

    /// App-level dependencies created at the composition root
    private let dependencies: AppDependencies

    // MARK: - Init

    init() {
        dependencies = AppDependencies()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            AppRootView(launchState: $launchState,
                        dependencies: dependencies)
        }
    }
}
