import Foundation
@testable import Arquitectura

// MARK: - PokemonListRepositoryMock

/// Mock implementation of PokemonListRepository for testing.
@MainActor
final class PokemonListRepositoryMock: PokemonListRepository {
    // MARK: - Properties

    var getPokemonListResult: Result<PokemonListRepositoryResult, Error> = .failure(NSError(domain: "test", code: 0))
    var getPokemonListCallCount = 0
    var lastLimit: Int?
    var lastOffset: Int?

    // MARK: - PokemonListRepository

    func getPokemonList(limit: Int, offset: Int) async throws -> PokemonListRepositoryResult {
        getPokemonListCallCount += 1
        lastLimit = limit
        lastOffset = offset
        return try getPokemonListResult.get()
    }
}
