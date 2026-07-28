import Foundation
@testable import Arquitectura

// MARK: - MockPokemonDetailUseCase

/// Mock implementation of PokemonDetailUseCase for testing.
actor MockPokemonDetailUseCase: PokemonDetailUseCase {
    // MARK: - Properties

    private(set) var executeResult: Result<PokemonDetailModel, Error> = .failure(NSError(domain: "test", code: 0))
    private(set) var executeCallCount = 0
    private(set) var executeLastPokemonId: Int?

    // MARK: - Init

    init() {}

    // MARK: - Test Helpers

    func setExecuteResult(_ result: Result<PokemonDetailModel, Error>) {
        executeResult = result
    }

    // MARK: - PokemonDetailUseCase

    func execute(pokemonId: Int) async throws -> PokemonDetailModel {
        executeCallCount += 1
        executeLastPokemonId = pokemonId

        switch executeResult {
        case let .success(model):
            return model
        case let .failure(error):
            throw error
        }
    }
}
