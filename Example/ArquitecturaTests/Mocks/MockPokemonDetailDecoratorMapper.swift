import Foundation
@testable import Arquitectura

// MARK: - MockPokemonDetailDecoratorMapper

/// Mock implementation of PokemonDetailDecoratorMapper for testing.
/// Uses struct since the protocol's map method is nonisolated and synchronous.
struct MockPokemonDetailDecoratorMapper: PokemonDetailDecoratorMapper {
    // MARK: - Properties

    /// The result to return from map calls.
    let mapResult: PokemonDetailPageDecorator

    // MARK: - PokemonDetailDecoratorMapper

    func map(_ model: PokemonDetailModel) -> PokemonDetailPageDecorator {
        mapResult
    }
}
