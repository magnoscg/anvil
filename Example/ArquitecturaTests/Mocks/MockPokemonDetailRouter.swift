import Foundation
@testable import Arquitectura

// MARK: - MockPokemonDetailRouter

/// Mock implementation of PokemonDetailRouter for testing
@MainActor
final class MockPokemonDetailRouter: PokemonDetailRouter {
    // MARK: - Properties

    private(set) var goBackCallCount = 0

    // MARK: - PokemonDetailRouter

    func goBack() {
        goBackCallCount += 1
    }
}
