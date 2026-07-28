import Foundation
import Testing
@testable import Arquitectura

// MARK: - PokemonListDecoratorMapperTests

@Suite
@MainActor
struct PokemonListDecoratorMapperTests {
    // MARK: - Properties

    private let mapper = PokemonListDecoratorMapperImpl()

    // MARK: - Tests

    @Test("Map single model correctly maps id, name, imageURL, and types")
    func mapSingleModel() {
        // Given
        let model = PokemonListModel(id: 25,
                                     name: "pikachu",
                                     imageURL: URL(string: "https://example.com/25.png"),
                                     types: [.electric])

        // When
        let decorator = mapper.map(model)

        // Then
        #expect(decorator.id == "25")
        #expect(decorator.name == "Pikachu")
        #expect(decorator.imageURL?.absoluteString == "https://example.com/25.png")
        #expect(decorator.types.count == 1)
        #expect(decorator.types.first?.id == "electric")
        #expect(decorator.types.first?.name == "Electric")
        #expect(decorator.types.first?.typeColor == .electric)
    }

    @Test("Map array of models returns correct count")
    func mapArrayOfModels() {
        // Given
        let models = [PokemonListModel(id: 1, name: "bulbasaur", imageURL: nil, types: [.grass, .poison]),
                      PokemonListModel(id: 4, name: "charmander", imageURL: nil, types: [.fire]),
                      PokemonListModel(id: 7, name: "squirtle", imageURL: nil, types: [.water])]

        // When
        let items = mapper.mapToItems(models)

        // Then
        #expect(items.count == 3)
        #expect(items[0].name == "Bulbasaur")
        #expect(items[1].name == "Charmander")
        #expect(items[2].name == "Squirtle")
    }

    @Test("Map empty array returns empty result")
    func mapEmptyArrayReturnsEmpty() {
        // When
        let items = mapper.mapToItems([])

        // Then
        #expect(items.isEmpty)
    }

    @Test("All PokemonType cases map to correct PokemonTypeColor")
    func allTypesMapCorrectly() {
        // Given
        let typeMapping: [(PokemonType, PokemonTypeColor)] = [(.normal, .normal),
                                                              (.fire, .fire),
                                                              (.water, .water),
                                                              (.grass, .grass),
                                                              (.electric, .electric),
                                                              (.ice, .ice),
                                                              (.fighting, .fighting),
                                                              (.poison, .poison),
                                                              (.ground, .ground),
                                                              (.flying, .flying),
                                                              (.psychic, .psychic),
                                                              (.bug, .bug),
                                                              (.rock, .rock),
                                                              (.ghost, .ghost),
                                                              (.dragon, .dragon),
                                                              (.dark, .dark),
                                                              (.steel, .steel),
                                                              (.fairy, .fairy),
                                                              (.unknown, .unknown)]

        for (pokemonType, expectedColor) in typeMapping {
            // When
            let model = PokemonListModel(id: 1, name: "test", imageURL: nil, types: [pokemonType])
            let decorator = mapper.map(model)

            // Then
            #expect(decorator.types.first?.typeColor == expectedColor,
                    "Expected \(expectedColor) for \(pokemonType), got \(String(describing: decorator.types.first?.typeColor))")
        }
    }

    @Test("Model with multiple types maps all types correctly")
    func modelWithMultipleTypes() {
        // Given
        let model = PokemonListModel(id: 6,
                                     name: "charizard",
                                     imageURL: nil,
                                     types: [.fire, .flying])

        // When
        let decorator = mapper.map(model)

        // Then
        #expect(decorator.types.count == 2)
        #expect(decorator.types[0].typeColor == .fire)
        #expect(decorator.types[1].typeColor == .flying)
    }
}
