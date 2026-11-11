import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokemonDetailUseCaseTests

@Suite
@MainActor
struct PokemonDetailUseCaseTests {
    // MARK: - Tests

    @Test("Execute returns model from repository")
    func executeReturnsModelFromRepository() async throws {
        let expectedModel = makeExpectedModel()
        let mockRepository = PokemonDetailRepositoryMock()
        mockRepository.fetchPokemonDetailResult = .success(expectedModel)
        let useCase = PokemonDetailUseCaseImpl(repository: mockRepository)

        let result = try await useCase.execute(pokemonId: 25)

        #expect(result.id == expectedModel.id)
        #expect(result.name == expectedModel.name)
        #expect(result.description == expectedModel.description)
        #expect(result.genus == expectedModel.genus)
    }

    @Test("Execute propagates the repository's DomainError")
    func executePropagatesRepositoryError() async {
        let mockRepository = PokemonDetailRepositoryMock()
        mockRepository.fetchPokemonDetailResult = .failure(DomainError.server)
        let useCase = PokemonDetailUseCaseImpl(repository: mockRepository)

        await #expect(throws: DomainError.server) { try await useCase.execute(pokemonId: 25) }
    }

    @Test("Execute propagates CancellationError")
    func executePropagatesCancellationError() async {
        let mockRepository = PokemonDetailRepositoryMock()
        mockRepository.fetchPokemonDetailResult = .failure(CancellationError())
        let useCase = PokemonDetailUseCaseImpl(repository: mockRepository)

        await #expect(throws: CancellationError.self) { try await useCase.execute(pokemonId: 25) }
    }

    @Test("Execute passes correct pokemonId to repository")
    func executePassesCorrectPokemonId() async throws {
        let mockRepository = PokemonDetailRepositoryMock()
        mockRepository.fetchPokemonDetailResult = .success(makeExpectedModel())
        let useCase = PokemonDetailUseCaseImpl(repository: mockRepository)

        _ = try await useCase.execute(pokemonId: 42)

        #expect(mockRepository.fetchPokemonDetailLastId == 42)
    }

    // MARK: - Test Helpers

    private func makeExpectedModel(description: String? = "A Pokemon description.",
                                   genus: String? = "Mouse Pokémon") -> PokemonDetailModel {
        PokemonDetailModel(id: 25,
                           name: "Pikachu",
                           imageURL: URL(string: "https://example.com/25.png"),
                           types: [.electric],
                           height: 4,
                           weight: 60,
                           stats: [PokemonStatModel(name: "hp", baseStat: 35)],
                           abilities: [PokemonAbilityModel(name: "static", isHidden: false)],
                           description: description,
                           genus: genus)
    }
}
