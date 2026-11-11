import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokemonDetailRepositoryTests

@Suite
struct PokemonDetailRepositoryTests {
    // MARK: - Tests

    @Test("Fetch with both endpoints successful returns complete model")
    func fetchWithBothEndpointsSuccessful() async throws {
        let detailDTO = makeDetailDTO()
        let speciesDTO = makeSpeciesDTO()
        let mockDataSource = PokemonDetailRemoteDataSourceMock()
        mockDataSource.fetchDetailResult = .success(detailDTO)
        mockDataSource.fetchSpeciesResult = .success(speciesDTO)
        let repository = PokemonDetailRepositoryImpl(remoteDataSource: mockDataSource,
                                                     dtoMapper: PokemonDetailDTOMapperImpl())

        let model = try await repository.fetchPokemonDetail(id: 25)

        #expect(model.id == 25)
        #expect(model.name == "Pikachu")
        #expect(model.description != nil)
        #expect(model.genus == "Mouse Pokémon")
    }

    @Test("Fetch with species failure returns model without description or genus")
    func fetchWithSpeciesFailure() async throws {
        let detailDTO = makeDetailDTO()
        let mockDataSource = PokemonDetailRemoteDataSourceMock()
        mockDataSource.fetchDetailResult = .success(detailDTO)
        mockDataSource.fetchSpeciesResult = .failure(NSError(domain: "test", code: 404))
        let repository = PokemonDetailRepositoryImpl(remoteDataSource: mockDataSource,
                                                     dtoMapper: PokemonDetailDTOMapperImpl())

        let model = try await repository.fetchPokemonDetail(id: 25)

        #expect(model.id == 25)
        #expect(model.name == "Pikachu")
        #expect(model.description == nil)
        #expect(model.genus == nil)
    }

    @Test("Fetch with detail failure throws the mapped DomainError")
    func fetchWithDetailFailure() async {
        let expectedError = APIError.httpError(statusCode: 500, data: nil)
        let mockDataSource = PokemonDetailRemoteDataSourceMock()
        mockDataSource.fetchDetailResult = .failure(expectedError)
        mockDataSource.fetchSpeciesResult = .success(makeSpeciesDTO())
        let repository = PokemonDetailRepositoryImpl(remoteDataSource: mockDataSource,
                                                     dtoMapper: PokemonDetailDTOMapperImpl())

        await #expect(throws: DomainError.server) { try await repository.fetchPokemonDetail(id: 25) }
    }

    @Test("Fetch with detail cancellation propagates CancellationError")
    func fetchWithDetailCancellation() async {
        let mockDataSource = PokemonDetailRemoteDataSourceMock()
        mockDataSource.fetchDetailResult = .failure(CancellationError())
        mockDataSource.fetchSpeciesResult = .success(makeSpeciesDTO())
        let repository = PokemonDetailRepositoryImpl(remoteDataSource: mockDataSource,
                                                     dtoMapper: PokemonDetailDTOMapperImpl())

        await #expect(throws: CancellationError.self) { try await repository.fetchPokemonDetail(id: 25) }
    }

    @Test("Fetch with species cancellation propagates CancellationError")
    func fetchWithSpeciesCancellation() async {
        let mockDataSource = PokemonDetailRemoteDataSourceMock()
        mockDataSource.fetchDetailResult = .success(makeDetailDTO())
        mockDataSource.fetchSpeciesResult = .failure(CancellationError())
        let repository = PokemonDetailRepositoryImpl(remoteDataSource: mockDataSource,
                                                     dtoMapper: PokemonDetailDTOMapperImpl())

        await #expect(throws: CancellationError.self) { try await repository.fetchPokemonDetail(id: 25) }
    }

    // MARK: - Test Helpers

    private func makeDetailDTO() -> PokemonDetailDTO {
        PokemonDetailDTO(id: 25,
                         name: "pikachu",
                         height: 4,
                         weight: 60,
                         stats: [StatSlotDTO(baseStat: 35, stat: StatDTO(name: "hp"))],
                         abilities: [AbilitySlotDTO(ability: AbilityDTO(name: "static"), isHidden: false, slot: 1)],
                         types: [TypeSlotDTO(slot: 1, type: TypeDTO(name: "electric"))],
                         sprites: SpritesDTO(frontDefault: "https://example.com/25.png", other: nil),
                         species: SpeciesReferenceDTO(url: "https://pokeapi.co/api/v2/pokemon-species/25/"))
    }

    private func makeSpeciesDTO() -> PokemonSpeciesDTO {
        PokemonSpeciesDTO(flavorTextEntries: [FlavorTextEntryDTO(flavorText: "A Pokemon description.",
                                                                 language: LanguageDTO(name: "en"),
                                                                 version: VersionDTO(name: "red"))],
                          genera: [GenusDTO(genus: "Mouse Pokémon", language: LanguageDTO(name: "en"))])
    }
}
