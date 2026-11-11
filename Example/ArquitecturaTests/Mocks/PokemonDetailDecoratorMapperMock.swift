import Foundation
@testable import Arquitectura

// MARK: - PokemonDetailDecoratorMapperMock

/// Mock implementation of PokemonDetailDecoratorMapper for testing.
/// Uses struct since the protocol's map method is nonisolated and synchronous.
struct PokemonDetailDecoratorMapperMock: PokemonDetailDecoratorMapper {
    // MARK: - Properties

    /// The result to return from map calls.
    let mapResult: PokemonDetailPageDecorator

    // MARK: - PokemonDetailDecoratorMapper

    func map(_ model: PokemonDetailModel) -> PokemonDetailPageDecorator {
        mapResult
    }
}
