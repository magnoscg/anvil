import SwiftUI

// MARK: - PokemonListRouteResolver

/// Resolves Pokemon list routes inside the root NavigationStack.
struct PokemonListRouteResolver: ViewModifier {
    // MARK: - Properties

    let appRouter: AppRouter
    let dependencies: AppDependencies

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: PokemonListRoute.self) { route in
                destination(for: route)
            }
    }

    // MARK: - Private

    @ViewBuilder
    private func destination(for route: PokemonListRoute) -> some View {
        switch route {
        case .list:
            PokemonListFactory.makeView(appRouter: appRouter, dependencies: dependencies)
        case let .detail(pokemonId):
            PokemonDetailFactory.makeView(pokemonId: pokemonId, appRouter: appRouter, dependencies: dependencies)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies Pokemon list route resolution to the view.
    func withPokemonListRoutes(appRouter: AppRouter, dependencies: AppDependencies) -> some View {
        modifier(PokemonListRouteResolver(appRouter: appRouter, dependencies: dependencies))
    }
}
