import Foundation

// MARK: - PokemonListRoute

/// Routes available within the Pokemon list flow.
enum PokemonListRoute: Hashable, Codable {
    case list
    case detail(pokemonId: Int)
}

// MARK: - PokemonListRouter

/// Protocol for Pokemon list navigation.
@MainActor
protocol PokemonListRouter: Sendable {
    func navigateToDetail(pokemonId: Int)
    func goBack()
}

// MARK: - PokemonListRouterImpl

/// AppRouter-backed implementation for Pokemon list navigation.
@MainActor
struct PokemonListRouterImpl: PokemonListRouter {
    // MARK: - Properties

    private let appRouter: AppRouter

    // MARK: - Init

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    // MARK: - PokemonListRouter

    func navigateToDetail(pokemonId: Int) {
        appRouter.push(PokemonListRoute.detail(pokemonId: pokemonId))
    }

    func goBack() {
        appRouter.pop()
    }
}
