import Foundation
@testable import Arquitectura

// MARK: - PokemonListRemoteDataSourceMock

/// Mock implementation of PokemonListRemoteDataSource for testing.
final class PokemonListRemoteDataSourceMock: PokemonListRemoteDataSource {
    // MARK: - Properties

    var fetchListResult: Result<PokemonListResponseDTO, Error> = .failure(NSError(domain: "test", code: 0))
    var fetchListCallCount = 0
    var fetchListLastLimit: Int?
    var fetchListLastOffset: Int?

    /// Result for any id that has no entry in `fetchDetailResults`.
    var fetchDetailResult: Result<PokemonListDTO, Error> = .failure(NSError(domain: "test", code: 0))
    /// Per-id results. They take precedence over `fetchDetailResult`.
    var fetchDetailResults: [Int: Result<PokemonListDTO, Error>] = [:]
    var fetchDetailCallCount = 0
    var fetchDetailLastId: Int?

    // MARK: - PokemonListRemoteDataSource

    func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponseDTO {
        fetchListCallCount += 1
        fetchListLastLimit = limit
        fetchListLastOffset = offset
        return try fetchListResult.get()
    }

    func fetchPokemonDetail(id: Int) async throws -> PokemonListDTO {
        fetchDetailCallCount += 1
        fetchDetailLastId = id
        return try (fetchDetailResults[id] ?? fetchDetailResult).get()
    }
}
