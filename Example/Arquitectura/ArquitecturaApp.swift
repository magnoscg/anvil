import SwiftUI

// MARK: - AppLaunchState

/// App launch state machine
enum AppLaunchState: Equatable {
    case splash
    case ready
}

// MARK: - ArquitecturaApp

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
            Group {
                switch launchState {
                case .splash:
                    SplashScreenFactory.makeView {
                        withAnimation(.easeOut(duration: 0.3)) {
                            launchState = .ready
                        }
                    }
                case .ready:
                    RootNavigationView(appRouter: appRouter,
                                       dependencies: dependencies)
                }
            }
        }
    }
}
