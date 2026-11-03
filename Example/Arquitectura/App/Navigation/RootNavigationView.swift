import SwiftUI

// MARK: - RootNavigationView

/// Root view that manages the NavigationStack and state persistence for one window.
/// The router and coordinator are owned by `AppRootView`; navigation logic lives in
/// AppNavigationCoordinator — this View is a thin shell.
struct RootNavigationView: View {
    // MARK: - Properties

    // @Bindable requires the concrete @Observable type, not the protocol
    @Bindable
    var appRouter: AppRouterImpl
    let dependencies: AppDependencies

    let coordinator: AppNavigationCoordinator

    /// Persists navigation state for restoration after app termination
    @SceneStorage("app.navigation.path")
    private var navigationData: Data?

    // MARK: - Init

    init(appRouter: AppRouterImpl,
         coordinator: AppNavigationCoordinator,
         dependencies: AppDependencies) {
        self.appRouter = appRouter
        self.coordinator = coordinator
        self.dependencies = dependencies
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $appRouter.path) {
            ArchitectureFactory.makeView(appRouter: appRouter)
                .withArchitectureRoutes(appRouter: appRouter)
                .withPokemonListRoutes(appRouter: appRouter, dependencies: dependencies)
        }
        .task(id: "restore") {
            coordinator.restoreNavigationState(from: navigationData)
        }
        .onChange(of: appRouter.path) { _, _ in
            coordinator.saveNavigationStateDebounced { data in
                navigationData = data
            }
        }
    }
}
