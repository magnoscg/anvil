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
        let mockRepository = MockPokemonListRepository()
        await mockRepository.setGetPokemonListResult(.success(makeRepositoryResult(hasMore: true)))
        let useCase = PokemonListUseCaseImpl(repository: mockRepository)

        _ = try await useCase.execute(page: 2, pageSize: 20)

        let lastLimit = await mockRepository.lastLimit
        let lastOffset = await mockRepository.lastOffset
        #expect(lastLimit == 20)
        #expect(lastOffset == 40)
    }

    @Test("Execute returns the repository's Pokemon and pagination info")
    func executeReturnsRepositoryResult() async throws {
        let mockRepository = MockPokemonListRepository()
        await mockRepository.setGetPokemonListResult(.success(makeRepositoryResult(hasMore: false)))
        let useCase = PokemonListUseCaseImpl(repository: mockRepository)

        let result = try await useCase.execute(page: 0, pageSize: 20)

        #expect(result.pokemon.map(\.id) == [25])
        #expect(result.hasMore == false)
        #expect(result.totalCount == 1)
    }

    @Test("Execute propagates the repository's DomainError")
    func executePropagatesDomainError() async {
        let mockRepository = MockPokemonListRepository()
        await mockRepository.setGetPokemonListResult(.failure(DomainError.server))
        let useCase = PokemonListUseCaseImpl(repository: mockRepository)

        do {
            _ = try await useCase.execute(page: 0, pageSize: 20)
            Issue.record("Expected an error to be thrown")
        } catch {
            #expect(error as? DomainError == .server)
        }
    }

    @Test("Execute propagates CancellationError")
    func executePropagatesCancellation() async {
        let mockRepository = MockPokemonListRepository()
        await mockRepository.setGetPokemonListResult(.failure(CancellationError()))
        let useCase = PokemonListUseCaseImpl(repository: mockRepository)

        do {
            _ = try await useCase.execute(page: 0, pageSize: 20)
            Issue.record("Expected CancellationError to be thrown")
        } catch {
            #expect(error is CancellationError)
        }
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
