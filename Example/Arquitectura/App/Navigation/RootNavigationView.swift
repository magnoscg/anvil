import SwiftUI

// MARK: - RootNavigationView

/// Root view that manages the NavigationStack and state persistence.
/// Navigation logic is delegated to AppNavigationCoordinator — this View is a thin shell.
struct RootNavigationView: View {
    // MARK: - Properties

    // @Bindable requires the concrete @Observable type, not the protocol
    @Bindable
    var appRouter: AppRouterImpl
    let dependencies: AppDependencies

    @State
    private var coordinator: AppNavigationCoordinator

    /// Persists navigation state for restoration after app termination
    @SceneStorage("app.navigation.path")
    private var navigationData: Data?

    // MARK: - Init

    init(appRouter: AppRouterImpl, dependencies: AppDependencies) {
        self.appRouter = appRouter
        self.dependencies = dependencies
        self._coordinator = State(initialValue: AppNavigationCoordinator(appRouter: appRouter))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $appRouter.path) {
            ArchitectureFactory.makeView(appRouter: appRouter)
                .withArchitectureRoutes(appRouter: appRouter)
                .withPokemonListRoutes(appRouter: appRouter, dependencies: dependencies)
        }
        .onOpenURL { url in
            coordinator.handleDeepLink(url)
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
