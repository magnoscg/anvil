import Foundation
@testable import Arquitectura

// MARK: - MockPokemonListUseCase

/// Mock implementation of PokemonListUseCase for testing
actor MockPokemonListUseCase: PokemonListUseCase {
    // MARK: - Properties

    private(set) var executeResult: Result<PokemonListResult, Error> = .success(PokemonListResult(pokemon: [],
                                                                                                  hasMore: false,
                                                                                                  totalCount: 0))
    private(set) var executeCallCount = 0
    private(set) var lastPage: Int?
    private(set) var lastPageSize: Int?

    // MARK: - Test Helpers

    func setExecuteResult(_ result: Result<PokemonListResult, Error>) {
        executeResult = result
    }

    // MARK: - PokemonListUseCase

    func execute(page: Int, pageSize: Int) async throws -> PokemonListResult {
        executeCallCount += 1
        lastPage = page
        lastPageSize = pageSize

        switch executeResult {
        case let .success(result):
            return result
        case let .failure(error):
            throw error
        }
    }
}
