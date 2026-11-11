import Foundation
@testable import Arquitectura

// MARK: - PokemonDetailRemoteDataSourceMock

/// Mock implementation of PokemonDetailRemoteDataSource for testing.
final class PokemonDetailRemoteDataSourceMock: PokemonDetailRemoteDataSource {
    // MARK: - Properties

    var fetchDetailResult: Result<PokemonDetailDTO, Error> = .failure(NSError(domain: "test", code: 0))
    var fetchDetailCallCount = 0
    var fetchDetailLastId: Int?

    var fetchSpeciesResult: Result<PokemonSpeciesDTO, Error> = .failure(NSError(domain: "test", code: 0))
    var fetchSpeciesCallCount = 0
    var fetchSpeciesLastId: Int?

    // MARK: - PokemonDetailRemoteDataSource

    func fetchPokemonDetail(id: Int) async throws -> PokemonDetailDTO {
        fetchDetailCallCount += 1
        fetchDetailLastId = id
        return try fetchDetailResult.get()
    }

    func fetchPokemonSpecies(id: Int) async throws -> PokemonSpeciesDTO {
        fetchSpeciesCallCount += 1
        fetchSpeciesLastId = id
        return try fetchSpeciesResult.get()
    }
}
