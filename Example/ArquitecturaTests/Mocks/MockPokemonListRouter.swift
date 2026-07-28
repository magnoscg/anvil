import Foundation
@testable import Arquitectura

// MARK: - MockPokemonListRouter

@MainActor
final class MockPokemonListRouter: PokemonListRouter {
    // MARK: - Properties

    private(set) var navigateToDetailCallCount = 0
    private(set) var lastNavigatedPokemonId: Int?
    private(set) var goBackCallCount = 0

    // MARK: - PokemonListRouter

    func navigateToDetail(pokemonId: Int) {
        navigateToDetailCallCount += 1
        lastNavigatedPokemonId = pokemonId
    }

    func goBack() {
        goBackCallCount += 1
    }
}
