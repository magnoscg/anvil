import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokemonDetailDecoratorMapperTests

@Suite
@MainActor
struct PokemonDetailDecoratorMapperTests {
    // MARK: - Properties

    private let mapper = PokemonDetailDecoratorMapperImpl()

    // MARK: - Height Conversion Tests

    @Test("Convert height from decimeters to meters formatted string")
    func convertHeight() {
        let model = makeModel(height: 4)

        let decorator = mapper.map(model)

        #expect(decorator.height == "0.4 m")
    }

    @Test("Convert large height from decimeters to meters")
    func convertLargeHeight() {
        let model = makeModel(height: 20)

        let decorator = mapper.map(model)

        #expect(decorator.height == "2.0 m")
    }

    // MARK: - Weight Conversion Tests

    @Test("Convert weight from hectograms to kilograms formatted string")
    func convertWeight() {
        let model = makeModel(weight: 60)

        let decorator = mapper.map(model)

        #expect(decorator.weight == "6.0 kg")
    }

    @Test("Convert large weight from hectograms to kilograms")
    func convertLargeWeight() {
        let model = makeModel(weight: 4600)

        let decorator = mapper.map(model)

        #expect(decorator.weight == "460.0 kg")
    }

    // MARK: - ID Format Tests

    @Test("Format single digit ID with leading zeros")
    func formatSingleDigitId() {
        let model = makeModel(id: 1)

        let decorator = mapper.map(model)

        #expect(decorator.formattedId == "#001")
    }

    @Test("Format double digit ID with leading zero")
    func formatDoubleDigitId() {
        let model = makeModel(id: 25)

        let decorator = mapper.map(model)

        #expect(decorator.formattedId == "#025")
    }

    @Test("Format triple digit ID without leading zeros")
    func formatTripleDigitId() {
        let model = makeModel(id: 150)

        let decorator = mapper.map(model)

        #expect(decorator.formattedId == "#150")
    }

    // MARK: - Stats Progress Tests

    @Test("Calculate stats progress as ratio to 255")
    func calculateStatsProgress() {
        let model = makeModel(stats: [PokemonStatModel(name: "hp", baseStat: 35),
                                      PokemonStatModel(name: "speed", baseStat: 255)])

        let decorator = mapper.map(model)

        #expect(decorator.stats.count == 2)
        #expect(decorator.stats[0].progress == 35.0 / 255.0)
        #expect(decorator.stats[1].progress == 1.0)
    }

    @Test("Map stat display names correctly")
    func mapStatDisplayNames() {
        let model = makeModel(stats: [PokemonStatModel(name: "hp", baseStat: 35),
                                      PokemonStatModel(name: "attack", baseStat: 55),
                                      PokemonStatModel(name: "defense", baseStat: 40),
                                      PokemonStatModel(name: "special-attack", baseStat: 50),
                                      PokemonStatModel(name: "special-defense", baseStat: 50),
                                      PokemonStatModel(name: "speed", baseStat: 90)])

        let decorator = mapper.map(model)

        #expect(decorator.stats[0].name == "HP")
        #expect(decorator.stats[1].name == "ATK")
        #expect(decorator.stats[2].name == "DEF")
        #expect(decorator.stats[3].name == "SpA")
        #expect(decorator.stats[4].name == "SpD")
        #expect(decorator.stats[5].name == "SPD")
    }

    // MARK: - Name Capitalization Tests

    @Test("Capitalize Pokemon name")
    func capitalizeName() {
        let model = makeModel(name: "pikachu")

        let decorator = mapper.map(model)

        #expect(decorator.name == "Pikachu")
    }

    // MARK: - Ability Mapping Tests

    @Test("Map ability names replacing hyphens with spaces and capitalizing")
    func mapAbilityNames() {
        let model = makeModel(abilities: [PokemonAbilityModel(name: "lightning-rod", isHidden: true),
                                          PokemonAbilityModel(name: "static", isHidden: false)])

        let decorator = mapper.map(model)

        #expect(decorator.abilities[0].name == "Lightning Rod")
        #expect(decorator.abilities[0].isHidden == true)
        #expect(decorator.abilities[1].name == "Static")
        #expect(decorator.abilities[1].isHidden == false)
    }

    // MARK: - Test Helpers

    private func makeModel(id: Int = 25,
                           name: String = "pikachu",
                           height: Int = 4,
                           weight: Int = 60,
                           stats: [PokemonStatModel] = [PokemonStatModel(name: "hp", baseStat: 35)],
                           abilities: [PokemonAbilityModel] = [PokemonAbilityModel(name: "static", isHidden: false)])
        -> PokemonDetailModel {
        PokemonDetailModel(id: id,
                           name: name,
                           imageURL: URL(string: "https://example.com/\(id).png"),
                           types: [.electric],
                           height: height,
                           weight: weight,
                           stats: stats,
                           abilities: abilities,
                           description: "A Pokemon description.",
                           genus: "Mouse Pokémon")
    }
}
