import Foundation
@testable import Arquitectura

// MARK: - MockPokemonListRepository

/// Mock implementation of PokemonListRepository for testing.
actor MockPokemonListRepository: PokemonListRepository {
    // MARK: - Properties

    private(set) var getPokemonListResult: Result<PokemonListRepositoryResult, Error> = .failure(NSError(domain: "test",
                                                                                                         code: 0))
    private(set) var getPokemonListCallCount = 0
    private(set) var lastLimit: Int?
    private(set) var lastOffset: Int?

    // MARK: - Init

    init() {}

    // MARK: - Test Helpers

    func setGetPokemonListResult(_ result: Result<PokemonListRepositoryResult, Error>) {
        getPokemonListResult = result
    }

    // MARK: - PokemonListRepository

    func getPokemonList(limit: Int, offset: Int) async throws -> PokemonListRepositoryResult {
        getPokemonListCallCount += 1
        lastLimit = limit
        lastOffset = offset

        switch getPokemonListResult {
        case let .success(result):
            return result
        case let .failure(error):
            throw error
        }
    }
}
