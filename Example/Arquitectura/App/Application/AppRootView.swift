import SwiftUI

// MARK: - AppRootView

/// Per-window root. Each window owns its own `AppRouterImpl` and `AppNavigationCoordinator`,
/// so navigating or restoring in one window never changes another.
/// `.onOpenURL` is installed here, above the splash, so a deep link that launches the app
/// is captured even before `RootNavigationView` exists.
struct AppRootView: View {
    // MARK: - Properties

    @Binding
    var launchState: AppLaunchState
    let dependencies: AppDependencies

    @State
    private var appRouter: AppRouterImpl

    @State
    private var coordinator: AppNavigationCoordinator

    // MARK: - Init

    init(launchState: Binding<AppLaunchState>, dependencies: AppDependencies) {
        let appRouter = AppRouterImpl()
        self._launchState = launchState
        self.dependencies = dependencies
        self.appRouter = appRouter
        self.coordinator = AppNavigationCoordinator(appRouter: appRouter)
    }

    // MARK: - Body

    var body: some View {
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
                                   coordinator: coordinator,
                                   dependencies: dependencies)
            }
        }
        .onOpenURL { url in
            coordinator.handleDeepLink(url)
        }
    }
}
