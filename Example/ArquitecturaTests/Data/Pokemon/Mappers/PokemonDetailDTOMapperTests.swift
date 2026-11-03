import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokemonDetailDTOMapperTests

@Suite
@MainActor
struct PokemonDetailDTOMapperTests {
    // MARK: - Properties

    private let mapper = PokemonDetailDTOMapperImpl()

    // MARK: - Full Mapping Tests

    @Test("Map detailDTO and speciesDTO to complete model")
    func mapFullDetailAndSpecies() {
        // Given
        let detailDTO = makeDetailDTO()
        let speciesDTO = makeSpeciesDTO()

        // When
        let model = mapper.map(detailDTO: detailDTO, speciesDTO: speciesDTO)

        // Then
        #expect(model.id == 25)
        #expect(model.name == "Pikachu")
        #expect(model.imageURL?
            .absoluteString ==
            "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png")
        #expect(model.height == 4)
        #expect(model.weight == 60)
        #expect(model.types == [.electric])
        #expect(model.stats.count == 6)
        #expect(model.abilities.count == 2)
        #expect(model.description != nil)
        #expect(model.genus == "Mouse Pokémon")
    }

    @Test("Map with nil speciesDTO returns nil description and genus")
    func mapWithNilSpecies() {
        // Given
        let detailDTO = makeDetailDTO()

        // When
        let model = mapper.map(detailDTO: detailDTO, speciesDTO: nil)

        // Then
        #expect(model.id == 25)
        #expect(model.name == "Pikachu")
        #expect(model.description == nil)
        #expect(model.genus == nil)
    }

    // MARK: - Species Filtering Tests

    @Test("Filter flavor text entries by English language")
    func filterFlavorTextByEnglish() {
        // Given
        let detailDTO = makeDetailDTO()
        let speciesDTO = PokemonSpeciesDTO(flavorTextEntries: [FlavorTextEntryDTO(flavorText: "ねずみポケモン",
                                                                                  language: LanguageDTO(name: "ja"),
                                                                                  version: VersionDTO(name: "red")),
                                                               FlavorTextEntryDTO(flavorText: "When several of these Pokemon gather, their electricity could build and cause lightning storms.",
                                                                                  language: LanguageDTO(name: "en"),
                                                                                  version: VersionDTO(name: "red")),
                                                               FlavorTextEntryDTO(flavorText: "Ratón eléctrico",
                                                                                  language: LanguageDTO(name: "es"),
                                                                                  version: VersionDTO(name: "red"))],
                                           genera: [GenusDTO(genus: "Mouse Pokémon",
                                                             language: LanguageDTO(name: "en"))])

        // When
        let model = mapper.map(detailDTO: detailDTO, speciesDTO: speciesDTO)

        // Then
        #expect(model
            .description ==
            "When several of these Pokemon gather, their electricity could build and cause lightning storms.")
    }

    @Test("Clean control characters in flavor text")
    func cleanControlCharactersInFlavorText() {
        // Given
        let detailDTO = makeDetailDTO()
        let speciesDTO =
            PokemonSpeciesDTO(flavorTextEntries: [FlavorTextEntryDTO(flavorText: "When several of\nthese POKéMON\u{000C}gather, their\relectricity could\nbuild and cause\u{000C}lightning storms.",
                                                                     language: LanguageDTO(name: "en"),
                                                                     version: VersionDTO(name: "red"))],
                              genera: [])

        // When
        let model = mapper.map(detailDTO: detailDTO, speciesDTO: speciesDTO)

        // Then
        #expect(model
            .description ==
            "When several of these POKéMON gather, their electricity could build and cause lightning storms.")
    }

    @Test("Filter genera by English language")
    func filterGeneraByEnglish() {
        // Given
        let detailDTO = makeDetailDTO()
        let speciesDTO = PokemonSpeciesDTO(flavorTextEntries: [],
                                           genera: [GenusDTO(genus: "ねずみポケモン", language: LanguageDTO(name: "ja")),
                                                    GenusDTO(genus: "Mouse Pokémon", language: LanguageDTO(name: "en")),
                                                    GenusDTO(genus: "Pokémon Ratón",
                                                             language: LanguageDTO(name: "es"))])

        // When
        let model = mapper.map(detailDTO: detailDTO, speciesDTO: speciesDTO)

        // Then
        #expect(model.genus == "Mouse Pokémon")
    }

    // MARK: - Stats Mapping Tests

    @Test("Map stats correctly with 6 stats")
    func mapStatsCorrectly() {
        // Given
        let detailDTO = makeDetailDTO()

        // When
        let model = mapper.map(detailDTO: detailDTO, speciesDTO: nil)

        // Then
        #expect(model.stats.count == 6)
        #expect(model.stats[0].name == "hp")
        #expect(model.stats[0].baseStat == 35)
        #expect(model.stats[1].name == "attack")
        #expect(model.stats[1].baseStat == 55)
        #expect(model.stats[2].name == "defense")
        #expect(model.stats[2].baseStat == 40)
        #expect(model.stats[3].name == "special-attack")
        #expect(model.stats[3].baseStat == 50)
        #expect(model.stats[4].name == "special-defense")
        #expect(model.stats[4].baseStat == 50)
        #expect(model.stats[5].name == "speed")
        #expect(model.stats[5].baseStat == 90)
    }

    // MARK: - Abilities Mapping Tests

    @Test("Map abilities with isHidden flag")
    func mapAbilitiesWithIsHidden() {
        // Given
        let detailDTO = makeDetailDTO()

        // When
        let model = mapper.map(detailDTO: detailDTO, speciesDTO: nil)

        // Then
        #expect(model.abilities.count == 2)
        #expect(model.abilities[0].name == "static")
        #expect(model.abilities[0].isHidden == false)
        #expect(model.abilities[1].name == "lightning-rod")
        #expect(model.abilities[1].isHidden == true)
    }

    // MARK: - Edge Cases

    @Test("Map with no English flavor text returns nil description")
    func mapWithNoEnglishFlavorText() {
        // Given
        let detailDTO = makeDetailDTO()
        let speciesDTO = PokemonSpeciesDTO(flavorTextEntries: [FlavorTextEntryDTO(flavorText: "ねずみポケモン",
                                                                                  language: LanguageDTO(name: "ja"),
                                                                                  version: VersionDTO(name: "red"))],
                                           genera: [GenusDTO(genus: "Mouse Pokémon",
                                                             language: LanguageDTO(name: "en"))])

        // When
        let model = mapper.map(detailDTO: detailDTO, speciesDTO: speciesDTO)

        // Then
        #expect(model.description == nil)
        #expect(model.genus == "Mouse Pokémon")
    }

    // MARK: - Test Helpers

    private func makeDetailDTO() -> PokemonDetailDTO {
        PokemonDetailDTO(id: 25,
                         name: "pikachu",
                         height: 4,
                         weight: 60,
                         stats: [StatSlotDTO(baseStat: 35, stat: StatDTO(name: "hp")),
                                 StatSlotDTO(baseStat: 55, stat: StatDTO(name: "attack")),
                                 StatSlotDTO(baseStat: 40, stat: StatDTO(name: "defense")),
                                 StatSlotDTO(baseStat: 50, stat: StatDTO(name: "special-attack")),
                                 StatSlotDTO(baseStat: 50, stat: StatDTO(name: "special-defense")),
                                 StatSlotDTO(baseStat: 90, stat: StatDTO(name: "speed"))],
                         abilities: [AbilitySlotDTO(ability: AbilityDTO(name: "static"), isHidden: false, slot: 1),
                                     AbilitySlotDTO(ability: AbilityDTO(name: "lightning-rod"), isHidden: true,
                                                    slot: 3)],
                         types: [TypeSlotDTO(slot: 1, type: TypeDTO(name: "electric"))],
                         sprites: SpritesDTO(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png",
                                             other: OtherSpritesDTO(officialArtwork: OfficialArtworkDTO(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png"))),
                         species: SpeciesReferenceDTO(url: "https://pokeapi.co/api/v2/pokemon-species/25/"))
    }

    private func makeSpeciesDTO() -> PokemonSpeciesDTO {
        PokemonSpeciesDTO(flavorTextEntries: [FlavorTextEntryDTO(flavorText: "When several of these POKéMON gather, their electricity could build and cause lightning storms.",
                                                                 language: LanguageDTO(name: "en"),
                                                                 version: VersionDTO(name: "red")),
                                              FlavorTextEntryDTO(flavorText: "ほっぺたの でんきぶくろに でんきを ためている。",
                                                                 language: LanguageDTO(name: "ja"),
                                                                 version: VersionDTO(name: "red"))],
                          genera: [GenusDTO(genus: "ねずみポケモン", language: LanguageDTO(name: "ja")),
                                   GenusDTO(genus: "Mouse Pokémon", language: LanguageDTO(name: "en"))])
    }
}
