import Foundation
@testable import Arquitectura

// MARK: - PokemonDetailRepositoryMock

/// Mock implementation of PokemonDetailRepository for testing.
final class PokemonDetailRepositoryMock: PokemonDetailRepository {
    // MARK: - Properties

    var fetchPokemonDetailResult: Result<PokemonDetailModel, Error> = .failure(NSError(domain: "test", code: 0))
    var fetchPokemonDetailCallCount = 0
    var fetchPokemonDetailLastId: Int?

    // MARK: - PokemonDetailRepository

    func fetchPokemonDetail(id: Int) async throws -> PokemonDetailModel {
        fetchPokemonDetailCallCount += 1
        fetchPokemonDetailLastId = id
        return try fetchPokemonDetailResult.get()
    }
}
