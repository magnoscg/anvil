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
        // Given
        let expectedModel = makeExpectedModel()
        let mockRepository = MockPokemonDetailRepository()
        await mockRepository.setFetchPokemonDetailResult(.success(expectedModel))
        let useCase = PokemonDetailUseCaseImpl(repository: mockRepository)

        // When
        let result = try await useCase.execute(pokemonId: 25)

        // Then
        #expect(result.id == expectedModel.id)
        #expect(result.name == expectedModel.name)
        #expect(result.description == expectedModel.description)
        #expect(result.genus == expectedModel.genus)
    }

    @Test("Execute maps repository error to DomainError")
    func executeMapsRepositoryError() async {
        // Given
        let expectedError = NSError(domain: "test", code: 500)
        let mockRepository = MockPokemonDetailRepository()
        await mockRepository.setFetchPokemonDetailResult(.failure(expectedError))
        let useCase = PokemonDetailUseCaseImpl(repository: mockRepository)

        // When/Then
        do {
            _ = try await useCase.execute(pokemonId: 25)
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error is DomainError)
            #expect(error as? DomainError == .unknown)
        }
    }

    @Test("Execute propagates CancellationError")
    func executePropagatesCancellationError() async {
        // Given
        let mockRepository = MockPokemonDetailRepository()
        await mockRepository.setFetchPokemonDetailResult(.failure(CancellationError()))
        let useCase = PokemonDetailUseCaseImpl(repository: mockRepository)

        // When/Then
        do {
            _ = try await useCase.execute(pokemonId: 25)
            #expect(Bool(false), "Expected CancellationError to be thrown")
        } catch {
            #expect(error is CancellationError)
        }
    }

    @Test("Execute passes correct pokemonId to repository")
    func executePassesCorrectPokemonId() async throws {
        // Given
        let mockRepository = MockPokemonDetailRepository()
        await mockRepository.setFetchPokemonDetailResult(.success(makeExpectedModel()))
        let useCase = PokemonDetailUseCaseImpl(repository: mockRepository)

        // When
        _ = try await useCase.execute(pokemonId: 42)

        // Then
        let lastId = await mockRepository.fetchPokemonDetailLastId
        #expect(lastId == 42)
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
