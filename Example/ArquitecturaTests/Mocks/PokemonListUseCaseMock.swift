import Foundation
@testable import Arquitectura

// MARK: - PokemonListUseCaseMock

/// Mock implementation of PokemonListUseCase for testing
@MainActor
final class PokemonListUseCaseMock: PokemonListUseCase {
    // MARK: - Properties

    var executeResult: Result<PokemonListResult, Error> = .success(PokemonListResult(pokemon: [],
                                                                                     hasMore: false,
                                                                                     totalCount: 0))
    var executeCallCount = 0
    var lastPage: Int?
    var lastPageSize: Int?
    /// Runs once while the call is in flight, so a test can re-enter the caller deterministically.
    var onExecute: (() async -> Void)?

    // MARK: - PokemonListUseCase

    func execute(page: Int, pageSize: Int) async throws -> PokemonListResult {
        executeCallCount += 1
        lastPage = page
        lastPageSize = pageSize
        let hook = onExecute
        onExecute = nil
        await hook?()
        return try executeResult.get()
    }
}
