import Foundation
@testable import Arquitectura

// MARK: - PokemonDetailRouterMock

/// Mock implementation of PokemonDetailRouter for testing
@MainActor
final class PokemonDetailRouterMock: PokemonDetailRouter {
    // MARK: - Properties

    private(set) var goBackCallCount = 0

    // MARK: - PokemonDetailRouter

    func goBack() {
        goBackCallCount += 1
    }
}
