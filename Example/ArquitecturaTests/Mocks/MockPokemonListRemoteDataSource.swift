import Foundation
@testable import Arquitectura

// MARK: - MockPokemonListRemoteDataSource

/// Mock implementation of PokemonListRemoteDataSource for testing.
actor MockPokemonListRemoteDataSource: PokemonListRemoteDataSource {
    // MARK: - Properties

    private(set) var fetchListResult: Result<PokemonListResponseDTO, Error> = .failure(NSError(domain: "test", code: 0))
    private(set) var fetchListCallCount = 0
    private(set) var fetchListLastLimit: Int?
    private(set) var fetchListLastOffset: Int?

    private(set) var fetchDetailResult: Result<PokemonListDTO, Error> = .failure(NSError(domain: "test", code: 0))
    private(set) var fetchDetailResults: [Int: Result<PokemonListDTO, Error>] = [:]
    private(set) var fetchDetailCallCount = 0
    private(set) var fetchDetailLastId: Int?

    // MARK: - Init

    init() {}

    // MARK: - Test Helpers

    func setFetchListResult(_ result: Result<PokemonListResponseDTO, Error>) {
        fetchListResult = result
    }

    func setFetchDetailResult(_ result: Result<PokemonListDTO, Error>) {
        fetchDetailResult = result
    }

    func setFetchDetailResult(_ result: Result<PokemonListDTO, Error>, forId id: Int) {
        fetchDetailResults[id] = result
    }

    // MARK: - PokemonListRemoteDataSource

    func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponseDTO {
        fetchListCallCount += 1
        fetchListLastLimit = limit
        fetchListLastOffset = offset

        switch fetchListResult {
        case let .success(dto):
            return dto
        case let .failure(error):
            throw error
        }
    }

    func fetchPokemonDetail(id: Int) async throws -> PokemonListDTO {
        fetchDetailCallCount += 1
        fetchDetailLastId = id

        // Use per-ID result if available, otherwise fall back to default
        let result = fetchDetailResults[id] ?? fetchDetailResult

        switch result {
        case let .success(dto):
            return dto
        case let .failure(error):
            throw error
        }
    }
}
