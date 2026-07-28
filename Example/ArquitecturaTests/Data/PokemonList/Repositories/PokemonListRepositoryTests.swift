import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokemonListRepositoryTests

@Suite
struct PokemonListRepositoryTests {
    // MARK: - Tests

    @Test("Fetch successful returns models sorted by ID")
    func fetchSuccessfulReturnsModels() async throws {
        // Given
        let listResponse = makeListResponse(count: 3, next: "next-url", results: [makeResultDTO(name: "bulbasaur",
                                                                                                id: 1),
                                                                                  makeResultDTO(name: "charmander",
                                                                                                id: 4),
                                                                                  makeResultDTO(name: "squirtle",
                                                                                                id: 7)])

        let mockDataSource = MockPokemonListRemoteDataSource()
        await mockDataSource.setFetchListResult(.success(listResponse))
        await mockDataSource.setFetchDetailResult(.success(makeDetailDTO(id: 1, name: "bulbasaur")), forId: 1)
        await mockDataSource.setFetchDetailResult(.success(makeDetailDTO(id: 4, name: "charmander")), forId: 4)
        await mockDataSource.setFetchDetailResult(.success(makeDetailDTO(id: 7, name: "squirtle")), forId: 7)

        let repository = PokemonListRepositoryImpl(remoteDataSource: mockDataSource,
                                                   dtoMapper: PokemonListDTOMapperImpl())

        // When
        let result = try await repository.getPokemonList(limit: 20, offset: 0)

        // Then
        #expect(result.pokemon.count == 3)
        #expect(result.pokemon[0].id == 1)
        #expect(result.pokemon[1].id == 4)
        #expect(result.pokemon[2].id == 7)
        #expect(result.totalCount == 3)
    }

    @Test("Fetch with detail failure returns partial results")
    func fetchWithDetailFailureReturnsPartialResults() async throws {
        // Given
        let listResponse = makeListResponse(count: 2, next: nil, results: [makeResultDTO(name: "bulbasaur", id: 1),
                                                                           makeResultDTO(name: "charmander", id: 4)])

        let mockDataSource = MockPokemonListRemoteDataSource()
        await mockDataSource.setFetchListResult(.success(listResponse))
        await mockDataSource.setFetchDetailResult(.success(makeDetailDTO(id: 1, name: "bulbasaur")), forId: 1)
        await mockDataSource.setFetchDetailResult(.failure(NSError(domain: "test", code: 404)), forId: 4)

        let repository = PokemonListRepositoryImpl(remoteDataSource: mockDataSource,
                                                   dtoMapper: PokemonListDTOMapperImpl())

        // When
        let result = try await repository.getPokemonList(limit: 20, offset: 0)

        // Then
        #expect(result.pokemon.count == 1)
        #expect(result.pokemon[0].id == 1)
    }

    @Test("Fetch propagates list error")
    func fetchPropagatesListError() async {
        // Given
        let expectedError = NSError(domain: "test", code: 500)

        let mockDataSource = MockPokemonListRemoteDataSource()
        await mockDataSource.setFetchListResult(.failure(expectedError))

        let repository = PokemonListRepositoryImpl(remoteDataSource: mockDataSource,
                                                   dtoMapper: PokemonListDTOMapperImpl())

        // When/Then
        do {
            _ = try await repository.getPokemonList(limit: 20, offset: 0)
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == "test")
            #expect(nsError.code == 500)
        }
    }

    @Test("Fetch hasMore true when next exists")
    func fetchHasMoreTrueWhenNextExists() async throws {
        // Given
        let listResponse = makeListResponse(count: 100, next: "https://pokeapi.co/api/v2/pokemon?offset=20&limit=20",
                                            results: [makeResultDTO(name: "bulbasaur", id: 1)])

        let mockDataSource = MockPokemonListRemoteDataSource()
        await mockDataSource.setFetchListResult(.success(listResponse))
        await mockDataSource.setFetchDetailResult(.success(makeDetailDTO(id: 1, name: "bulbasaur")), forId: 1)

        let repository = PokemonListRepositoryImpl(remoteDataSource: mockDataSource,
                                                   dtoMapper: PokemonListDTOMapperImpl())

        // When
        let result = try await repository.getPokemonList(limit: 20, offset: 0)

        // Then
        #expect(result.hasMore == true)
    }

    @Test("Fetch hasMore false when next is nil")
    func fetchHasMoreFalseWhenNextIsNil() async throws {
        // Given
        let listResponse = makeListResponse(count: 1, next: nil,
                                            results: [makeResultDTO(name: "bulbasaur", id: 1)])

        let mockDataSource = MockPokemonListRemoteDataSource()
        await mockDataSource.setFetchListResult(.success(listResponse))
        await mockDataSource.setFetchDetailResult(.success(makeDetailDTO(id: 1, name: "bulbasaur")), forId: 1)

        let repository = PokemonListRepositoryImpl(remoteDataSource: mockDataSource,
                                                   dtoMapper: PokemonListDTOMapperImpl())

        // When
        let result = try await repository.getPokemonList(limit: 20, offset: 0)

        // Then
        #expect(result.hasMore == false)
    }

    @Test("Fetch propagates CancellationError")
    func fetchPropagatesCancellationError() async {
        // Given
        let mockDataSource = MockPokemonListRemoteDataSource()
        await mockDataSource.setFetchListResult(.success(makeListResponse(count: 1, next: nil,
                                                                          results: [makeResultDTO(name: "bulbasaur",
                                                                                                  id: 1)])))
        await mockDataSource.setFetchDetailResult(.failure(CancellationError()), forId: 1)

        let repository = PokemonListRepositoryImpl(remoteDataSource: mockDataSource,
                                                   dtoMapper: PokemonListDTOMapperImpl())

        // When/Then
        do {
            _ = try await repository.getPokemonList(limit: 20, offset: 0)
            #expect(Bool(false), "Expected CancellationError to be thrown")
        } catch {
            #expect(error is CancellationError)
        }
    }

    // MARK: - Test Helpers

    private func makeListResponse(count: Int, next: String?,
                                  results: [PokemonListResultDTO]) -> PokemonListResponseDTO {
        PokemonListResponseDTO(count: count, next: next, previous: nil, results: results)
    }

    private func makeResultDTO(name: String, id: Int) -> PokemonListResultDTO {
        PokemonListResultDTO(name: name, url: "https://pokeapi.co/api/v2/pokemon/\(id)/")
    }

    private func makeDetailDTO(id: Int, name: String) -> PokemonListDTO {
        PokemonListDTO(id: id,
                       name: name,
                       types: [TypeSlotDTO(slot: 1, type: TypeDTO(name: "grass"))],
                       sprites: SpritesDTO(frontDefault: "https://example.com/\(id).png",
                                           other: OtherSpritesDTO(officialArtwork: OfficialArtworkDTO(frontDefault: "https://example.com/artwork/\(id).png"))))
    }
}
