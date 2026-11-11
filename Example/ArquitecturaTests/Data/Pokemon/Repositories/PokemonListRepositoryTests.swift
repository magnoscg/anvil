import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokemonListRepositoryTests

@Suite
struct PokemonListRepositoryTests {
    // MARK: - Tests

    @Test("Fetch successful returns models sorted by ID")
    func fetchSuccessfulReturnsModels() async throws {
        let listResponse = makeListResponse(count: 3, next: "next-url", results: [makeResultDTO(name: "bulbasaur",
                                                                                                id: 1),
                                                                                  makeResultDTO(name: "charmander",
                                                                                                id: 4),
                                                                                  makeResultDTO(name: "squirtle",
                                                                                                id: 7)])
        let mockDataSource = PokemonListRemoteDataSourceMock()
        mockDataSource.fetchListResult = .success(listResponse)
        mockDataSource.fetchDetailResults[1] = .success(makeDetailDTO(id: 1, name: "bulbasaur"))
        mockDataSource.fetchDetailResults[4] = .success(makeDetailDTO(id: 4, name: "charmander"))
        mockDataSource.fetchDetailResults[7] = .success(makeDetailDTO(id: 7, name: "squirtle"))
        let repository = PokemonListRepositoryImpl(remoteDataSource: mockDataSource,
                                                   dtoMapper: PokemonListDTOMapperImpl())

        let result = try await repository.getPokemonList(limit: 20, offset: 0)

        #expect(result.pokemon.count == 3)
        #expect(result.pokemon[0].id == 1)
        #expect(result.pokemon[1].id == 4)
        #expect(result.pokemon[2].id == 7)
        #expect(result.totalCount == 3)
    }

    @Test("Fetch with detail failure returns partial results")
    func fetchWithDetailFailureReturnsPartialResults() async throws {
        let listResponse = makeListResponse(count: 2, next: nil, results: [makeResultDTO(name: "bulbasaur", id: 1),
                                                                           makeResultDTO(name: "charmander", id: 4)])
        let mockDataSource = PokemonListRemoteDataSourceMock()
        mockDataSource.fetchListResult = .success(listResponse)
        mockDataSource.fetchDetailResults[1] = .success(makeDetailDTO(id: 1, name: "bulbasaur"))
        mockDataSource.fetchDetailResults[4] = .failure(NSError(domain: "test", code: 404))
        let repository = PokemonListRepositoryImpl(remoteDataSource: mockDataSource,
                                                   dtoMapper: PokemonListDTOMapperImpl())

        let result = try await repository.getPokemonList(limit: 20, offset: 0)

        #expect(result.pokemon.count == 1)
        #expect(result.pokemon[0].id == 1)
    }

    @Test("Fetch throws the mapped DomainError when every detail request fails")
    func fetchWithAllDetailFailuresThrows() async {
        let listResponse = makeListResponse(count: 2, next: "next-url",
                                            results: [makeResultDTO(name: "bulbasaur", id: 1),
                                                      makeResultDTO(name: "charmander",
                                                                    id: 4)])
        let mockDataSource = PokemonListRemoteDataSourceMock()
        mockDataSource.fetchListResult = .success(listResponse)
        mockDataSource.fetchDetailResults[1] = .failure(APIError.networkError(URLError(.timedOut)))
        mockDataSource.fetchDetailResults[4] = .failure(APIError.networkError(URLError(.timedOut)))
        let repository = PokemonListRepositoryImpl(remoteDataSource: mockDataSource,
                                                   dtoMapper: PokemonListDTOMapperImpl())

        await #expect(throws: DomainError.network) { try await repository.getPokemonList(limit: 20, offset: 0) }
    }

    @Test("Fetch with list failure throws the mapped DomainError")
    func fetchPropagatesListError() async {
        let expectedError = APIError.networkError(URLError(.notConnectedToInternet))
        let mockDataSource = PokemonListRemoteDataSourceMock()
        mockDataSource.fetchListResult = .failure(expectedError)
        let repository = PokemonListRepositoryImpl(remoteDataSource: mockDataSource,
                                                   dtoMapper: PokemonListDTOMapperImpl())

        await #expect(throws: DomainError.network) { try await repository.getPokemonList(limit: 20, offset: 0) }
    }

    @Test("Fetch hasMore true when next exists")
    func fetchHasMoreTrueWhenNextExists() async throws {
        let listResponse = makeListResponse(count: 100, next: "https://pokeapi.co/api/v2/pokemon?offset=20&limit=20",
                                            results: [makeResultDTO(name: "bulbasaur", id: 1)])
        let mockDataSource = PokemonListRemoteDataSourceMock()
        mockDataSource.fetchListResult = .success(listResponse)
        mockDataSource.fetchDetailResults[1] = .success(makeDetailDTO(id: 1, name: "bulbasaur"))
        let repository = PokemonListRepositoryImpl(remoteDataSource: mockDataSource,
                                                   dtoMapper: PokemonListDTOMapperImpl())

        let result = try await repository.getPokemonList(limit: 20, offset: 0)

        #expect(result.hasMore == true)
    }

    @Test("Fetch hasMore false when next is nil")
    func fetchHasMoreFalseWhenNextIsNil() async throws {
        let listResponse = makeListResponse(count: 1, next: nil,
                                            results: [makeResultDTO(name: "bulbasaur", id: 1)])
        let mockDataSource = PokemonListRemoteDataSourceMock()
        mockDataSource.fetchListResult = .success(listResponse)
        mockDataSource.fetchDetailResults[1] = .success(makeDetailDTO(id: 1, name: "bulbasaur"))
        let repository = PokemonListRepositoryImpl(remoteDataSource: mockDataSource,
                                                   dtoMapper: PokemonListDTOMapperImpl())

        let result = try await repository.getPokemonList(limit: 20, offset: 0)

        #expect(result.hasMore == false)
    }

    @Test("Fetch propagates CancellationError")
    func fetchPropagatesCancellationError() async {
        let mockDataSource = PokemonListRemoteDataSourceMock()
        mockDataSource.fetchListResult = .success(makeListResponse(count: 1, next: nil,
                                                                   results: [makeResultDTO(name: "bulbasaur", id: 1)]))
        mockDataSource.fetchDetailResults[1] = .failure(CancellationError())
        let repository = PokemonListRepositoryImpl(remoteDataSource: mockDataSource,
                                                   dtoMapper: PokemonListDTOMapperImpl())

        await #expect(throws: CancellationError.self) { try await repository.getPokemonList(limit: 20, offset: 0) }
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
