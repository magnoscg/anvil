import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokemonListUseCaseTests

@Suite
@MainActor
struct PokemonListUseCaseTests {
    // MARK: - Tests

    @Test("Execute converts the page into a limit and offset")
    func executeConvertsPageToOffset() async throws {
        let mockRepository = PokemonListRepositoryMock()
        mockRepository.getPokemonListResult = .success(makeRepositoryResult(hasMore: true))
        let useCase = PokemonListUseCaseImpl(repository: mockRepository)

        _ = try await useCase.execute(page: 2, pageSize: 20)

        #expect(mockRepository.lastLimit == 20)
        #expect(mockRepository.lastOffset == 40)
    }

    @Test("Execute returns the repository's Pokemon and pagination info")
    func executeReturnsRepositoryResult() async throws {
        let mockRepository = PokemonListRepositoryMock()
        mockRepository.getPokemonListResult = .success(makeRepositoryResult(hasMore: false))
        let useCase = PokemonListUseCaseImpl(repository: mockRepository)

        let result = try await useCase.execute(page: 0, pageSize: 20)

        #expect(result.pokemon.map(\.id) == [25])
        #expect(result.hasMore == false)
        #expect(result.totalCount == 1)
    }

    @Test("Execute propagates the repository's DomainError")
    func executePropagatesDomainError() async {
        let mockRepository = PokemonListRepositoryMock()
        mockRepository.getPokemonListResult = .failure(DomainError.server)
        let useCase = PokemonListUseCaseImpl(repository: mockRepository)

        await #expect(throws: DomainError.server) { try await useCase.execute(page: 0, pageSize: 20) }
    }

    @Test("Execute propagates CancellationError")
    func executePropagatesCancellation() async {
        let mockRepository = PokemonListRepositoryMock()
        mockRepository.getPokemonListResult = .failure(CancellationError())
        let useCase = PokemonListUseCaseImpl(repository: mockRepository)

        await #expect(throws: CancellationError.self) { try await useCase.execute(page: 0, pageSize: 20) }
    }

    // MARK: - Helpers

    private func makeRepositoryResult(hasMore: Bool) -> PokemonListRepositoryResult {
        PokemonListRepositoryResult(pokemon: [PokemonSummaryModel(id: 25,
                                                                  name: "Pikachu",
                                                                  imageURL: nil,
                                                                  types: [.electric])],
                                    totalCount: 1,
                                    hasMore: hasMore)
    }
}
