import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokemonDetailRepositoryTests

@Suite
struct PokemonDetailRepositoryTests {
    // MARK: - Tests

    @Test("Fetch with both endpoints successful returns complete model")
    func fetchWithBothEndpointsSuccessful() async throws {
        // Given
        let detailDTO = makeDetailDTO()
        let speciesDTO = makeSpeciesDTO()

        let mockDataSource = MockPokemonDetailRemoteDataSource()
        await mockDataSource.setFetchDetailResult(.success(detailDTO))
        await mockDataSource.setFetchSpeciesResult(.success(speciesDTO))

        let repository = PokemonDetailRepositoryImpl(remoteDataSource: mockDataSource,
                                                     dtoMapper: PokemonDetailDTOMapperImpl())

        // When
        let model = try await repository.fetchPokemonDetail(id: 25)

        // Then
        #expect(model.id == 25)
        #expect(model.name == "Pikachu")
        #expect(model.description != nil)
        #expect(model.genus == "Mouse Pokémon")
    }

    @Test("Fetch with species failure returns model without description or genus")
    func fetchWithSpeciesFailure() async throws {
        // Given
        let detailDTO = makeDetailDTO()

        let mockDataSource = MockPokemonDetailRemoteDataSource()
        await mockDataSource.setFetchDetailResult(.success(detailDTO))
        await mockDataSource.setFetchSpeciesResult(.failure(NSError(domain: "test", code: 404)))

        let repository = PokemonDetailRepositoryImpl(remoteDataSource: mockDataSource,
                                                     dtoMapper: PokemonDetailDTOMapperImpl())

        // When
        let model = try await repository.fetchPokemonDetail(id: 25)

        // Then
        #expect(model.id == 25)
        #expect(model.name == "Pikachu")
        #expect(model.description == nil)
        #expect(model.genus == nil)
    }

    @Test("Fetch with detail failure propagates the error")
    func fetchWithDetailFailure() async {
        // Given
        let expectedError = NSError(domain: "test", code: 500)

        let mockDataSource = MockPokemonDetailRemoteDataSource()
        await mockDataSource.setFetchDetailResult(.failure(expectedError))
        await mockDataSource.setFetchSpeciesResult(.success(makeSpeciesDTO()))

        let repository = PokemonDetailRepositoryImpl(remoteDataSource: mockDataSource,
                                                     dtoMapper: PokemonDetailDTOMapperImpl())

        // When/Then
        do {
            _ = try await repository.fetchPokemonDetail(id: 25)
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == "test")
            #expect(nsError.code == 500)
        }
    }

    @Test("Fetch with detail cancellation propagates CancellationError")
    func fetchWithDetailCancellation() async {
        // Given
        let mockDataSource = MockPokemonDetailRemoteDataSource()
        await mockDataSource.setFetchDetailResult(.failure(CancellationError()))
        await mockDataSource.setFetchSpeciesResult(.success(makeSpeciesDTO()))

        let repository = PokemonDetailRepositoryImpl(remoteDataSource: mockDataSource,
                                                     dtoMapper: PokemonDetailDTOMapperImpl())

        // When/Then
        do {
            _ = try await repository.fetchPokemonDetail(id: 25)
            #expect(Bool(false), "Expected CancellationError to be thrown")
        } catch {
            #expect(error is CancellationError)
        }
    }

    @Test("Fetch with species cancellation propagates CancellationError")
    func fetchWithSpeciesCancellation() async {
        // Given
        let mockDataSource = MockPokemonDetailRemoteDataSource()
        await mockDataSource.setFetchDetailResult(.success(makeDetailDTO()))
        await mockDataSource.setFetchSpeciesResult(.failure(CancellationError()))

        let repository = PokemonDetailRepositoryImpl(remoteDataSource: mockDataSource,
                                                     dtoMapper: PokemonDetailDTOMapperImpl())

        // When/Then
        do {
            _ = try await repository.fetchPokemonDetail(id: 25)
            #expect(Bool(false), "Expected CancellationError to be thrown from species")
        } catch {
            #expect(error is CancellationError)
        }
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
