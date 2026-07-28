import Foundation

// MARK: - ArchitectureDetailRouter

/// Protocol for Architecture Detail feature navigation.
/// ViewModels depend only on this protocol, not on AppRouter directly.
/// Must be Sendable for Swift 6 strict concurrency.
@MainActor
protocol ArchitectureDetailRouter: Sendable {
    /// Navigates to the PokemonList screen
    func navigateToPokemonList()

    /// Goes back to the previous screen
    func goBack()
}

// MARK: - ArchitectureDetailRouterImpl

/// Implementation of ArchitectureDetailRouter that delegates navigation to the generic AppRouter.
@MainActor
struct ArchitectureDetailRouterImpl: ArchitectureDetailRouter {
    // MARK: - Properties

    private let appRouter: AppRouter

    // MARK: - Init

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    // MARK: - Public Methods

    func navigateToPokemonList() {
        appRouter.push(PokemonListRoute.list)
    }

    func goBack() {
        appRouter.pop()
    }
}
