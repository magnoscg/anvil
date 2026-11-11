import Foundation
@testable import Arquitectura

// MARK: - PokemonDetailUseCaseMock

/// Mock implementation of PokemonDetailUseCase for testing.
final class PokemonDetailUseCaseMock: PokemonDetailUseCase {
    // MARK: - Properties

    var executeResult: Result<PokemonDetailModel, Error> = .failure(NSError(domain: "test", code: 0))
    var executeCallCount = 0
    var executeLastPokemonId: Int?

    // MARK: - PokemonDetailUseCase

    func execute(pokemonId: Int) async throws -> PokemonDetailModel {
        executeCallCount += 1
        executeLastPokemonId = pokemonId
        return try executeResult.get()
    }
}
