import SwiftUI

// MARK: - AppLaunchState

/// App launch state machine
enum AppLaunchState: Equatable {
    case splash
    case ready
}

// MARK: - ArquitecturaApp

/// Composition root. The root navigation is always installed so that `.onOpenURL`
/// and state restoration are active from launch; the splash is drawn on top of it
/// until its animation finishes, which keeps deep links received during the splash.
@main
struct ArquitecturaApp: App {
    // MARK: - Properties

    @State
    private var launchState: AppLaunchState = .splash

    @State
    private var appRouter = AppRouterImpl()

    /// App-level dependencies created at the composition root
    private let dependencies: AppDependencies

    // MARK: - Init

    init() {
        dependencies = AppDependencies()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootNavigationView(appRouter: appRouter,
                               dependencies: dependencies)
                .accessibilityHidden(launchState == .splash)
                .overlay {
                    if launchState == .splash {
                        SplashScreenFactory.makeView {
                            withAnimation(.easeOut(duration: 0.3)) {
                                launchState = .ready
                            }
                        }
                    }
                }
        }
    }
}
