import Foundation
@testable import Arquitectura

// MARK: - PokemonListDecoratorMapperMock

/// Mock implementation of PokemonListDecoratorMapper for testing
struct PokemonListDecoratorMapperMock: PokemonListDecoratorMapper {
    // MARK: - Properties

    var mapResult: PokemonListItemDecorator?
    var mapToItemsResult: [PokemonListItemDecorator]?

    // MARK: - PokemonListDecoratorMapper

    func map(_ model: PokemonSummaryModel) -> PokemonListItemDecorator {
        if let mapResult {
            return mapResult
        }
        return PokemonListItemDecorator(id: String(model.id),
                                        numericId: model.id,
                                        name: model.name.capitalized,
                                        imageURL: model.imageURL,
                                        types: [])
    }

    func mapToItems(_ models: [PokemonSummaryModel]) -> [PokemonListItemDecorator] {
        if let mapToItemsResult {
            return mapToItemsResult
        }
        return models.map { map($0) }
    }
}
