import Foundation
@testable import Arquitectura

// MARK: - MockPokemonDetailRepository

/// Mock implementation of PokemonDetailRepository for testing.
actor MockPokemonDetailRepository: PokemonDetailRepository {
    // MARK: - Properties

    private(set) var fetchPokemonDetailResult: Result<PokemonDetailModel, Error> = .failure(NSError(domain: "test",
                                                                                                    code: 0))
    private(set) var fetchPokemonDetailCallCount = 0
    private(set) var fetchPokemonDetailLastId: Int?

    // MARK: - Init

    init() {}

    // MARK: - Test Helpers

    func setFetchPokemonDetailResult(_ result: Result<PokemonDetailModel, Error>) {
        fetchPokemonDetailResult = result
    }

    // MARK: - PokemonDetailRepository

    func fetchPokemonDetail(id: Int) async throws -> PokemonDetailModel {
        fetchPokemonDetailCallCount += 1
        fetchPokemonDetailLastId = id

        switch fetchPokemonDetailResult {
        case let .success(model):
            return model
        case let .failure(error):
            throw error
        }
    }
}
