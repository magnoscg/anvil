import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokemonListDTOMapperTests

@Suite
struct PokemonListDTOMapperTests {
    // MARK: - Properties

    private let mapper = PokemonListDTOMapperImpl()

    // MARK: - Basic Mapping Tests

    @Test("Maps DTO to domain correctly with capitalized name and types")
    func mapsToDomainCorrectly() {
        // Given
        let dto = makeDTO(id: 25, name: "pikachu",
                          types: [TypeSlotDTO(slot: 1, type: TypeDTO(name: "electric"))],
                          sprites: makeSprites(frontDefault: nil,
                                               officialArtwork: "https://example.com/artwork/25.png"))

        // When
        let model = mapper.mapToDomain(dto)

        // Then
        #expect(model.id == 25)
        #expect(model.name == "Pikachu")
        #expect(model.types == [.electric])
        #expect(model.imageURL?.absoluteString == "https://example.com/artwork/25.png")
    }

    // MARK: - Image URL Tests

    @Test("Prefers official artwork over default sprite")
    func prefersOfficialArtworkOverDefault() {
        // Given
        let dto = makeDTO(id: 1, name: "bulbasaur",
                          types: [],
                          sprites: makeSprites(frontDefault: "https://example.com/default/1.png",
                                               officialArtwork: "https://example.com/artwork/1.png"))

        // When
        let model = mapper.mapToDomain(dto)

        // Then
        #expect(model.imageURL?.absoluteString == "https://example.com/artwork/1.png")
    }

    @Test("Falls back to default sprite when no official artwork")
    func fallsBackToDefaultSprite() {
        // Given
        let dto = makeDTO(id: 1, name: "bulbasaur",
                          types: [],
                          sprites: makeSprites(frontDefault: "https://example.com/default/1.png",
                                               officialArtwork: nil))

        // When
        let model = mapper.mapToDomain(dto)

        // Then
        #expect(model.imageURL?.absoluteString == "https://example.com/default/1.png")
    }

    @Test("Returns nil imageURL when no sprites available")
    func returnsNilImageURLWhenNoSprites() {
        // Given
        let dto = makeDTO(id: 1, name: "bulbasaur",
                          types: [],
                          sprites: makeSprites(frontDefault: nil, officialArtwork: nil))

        // When
        let model = mapper.mapToDomain(dto)

        // Then
        #expect(model.imageURL == nil)
    }

    // MARK: - Type Mapping Tests

    @Test("Maps single type correctly")
    func mapsSingleTypeCorrectly() {
        // Given
        let dto = makeDTO(id: 4, name: "charmander",
                          types: [TypeSlotDTO(slot: 1, type: TypeDTO(name: "fire"))],
                          sprites: makeSprites(frontDefault: nil, officialArtwork: nil))

        // When
        let model = mapper.mapToDomain(dto)

        // Then
        #expect(model.types == [.fire])
    }

    @Test("Maps multiple types sorted by slot")
    func mapsMultipleTypesSortedBySlot() {
        // Given
        let dto = makeDTO(id: 1, name: "bulbasaur",
                          types: [TypeSlotDTO(slot: 2, type: TypeDTO(name: "poison")),
                                  TypeSlotDTO(slot: 1, type: TypeDTO(name: "grass"))],
                          sprites: makeSprites(frontDefault: nil, officialArtwork: nil))

        // When
        let model = mapper.mapToDomain(dto)

        // Then
        #expect(model.types == [.grass, .poison])
    }

    // MARK: - Array Mapping Tests

    @Test("Maps array of DTOs correctly")
    func mapsArrayOfDTOs() {
        // Given
        let dtos = [makeDTO(id: 1, name: "bulbasaur", types: [],
                            sprites: makeSprites(frontDefault: nil, officialArtwork: nil)),
                    makeDTO(id: 4, name: "charmander", types: [],
                            sprites: makeSprites(frontDefault: nil, officialArtwork: nil))]

        // When
        let models = mapper.mapToDomain(dtos)

        // Then
        #expect(models.count == 2)
        #expect(models[0].id == 1)
        #expect(models[0].name == "Bulbasaur")
        #expect(models[1].id == 4)
        #expect(models[1].name == "Charmander")
    }

    // MARK: - Test Helpers

    private func makeDTO(id: Int, name: String, types: [TypeSlotDTO], sprites: SpritesDTO) -> PokemonListDTO {
        PokemonListDTO(id: id, name: name, types: types, sprites: sprites)
    }

    private func makeSprites(frontDefault: String?, officialArtwork: String?) -> SpritesDTO {
        let artwork: OtherSpritesDTO? = if let officialArtwork {
            OtherSpritesDTO(officialArtwork: OfficialArtworkDTO(frontDefault: officialArtwork))
        } else {
            nil
        }
        return SpritesDTO(frontDefault: frontDefault, other: artwork)
    }
}
