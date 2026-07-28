import Foundation
@testable import Arquitectura

// MARK: - MockPokemonDetailRemoteDataSource

/// Mock implementation of PokemonDetailRemoteDataSource for testing.
actor MockPokemonDetailRemoteDataSource: PokemonDetailRemoteDataSource {
    // MARK: - Properties

    private(set) var fetchDetailResult: Result<PokemonDetailDTO, Error> = .failure(NSError(domain: "test", code: 0))
    private(set) var fetchDetailCallCount = 0
    private(set) var fetchDetailLastId: Int?

    private(set) var fetchSpeciesResult: Result<PokemonSpeciesDTO, Error> = .failure(NSError(domain: "test", code: 0))
    private(set) var fetchSpeciesCallCount = 0
    private(set) var fetchSpeciesLastId: Int?

    // MARK: - Init

    init() {}

    // MARK: - Test Helpers

    func setFetchDetailResult(_ result: Result<PokemonDetailDTO, Error>) {
        fetchDetailResult = result
    }

    func setFetchSpeciesResult(_ result: Result<PokemonSpeciesDTO, Error>) {
        fetchSpeciesResult = result
    }

    // MARK: - PokemonDetailRemoteDataSource

    func fetchPokemonDetail(id: Int) async throws -> PokemonDetailDTO {
        fetchDetailCallCount += 1
        fetchDetailLastId = id

        switch fetchDetailResult {
        case let .success(dto):
            return dto
        case let .failure(error):
            throw error
        }
    }

    func fetchPokemonSpecies(id: Int) async throws -> PokemonSpeciesDTO {
        fetchSpeciesCallCount += 1
        fetchSpeciesLastId = id

        switch fetchSpeciesResult {
        case let .success(dto):
            return dto
        case let .failure(error):
            throw error
        }
    }
}
