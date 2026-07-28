import Foundation

// MARK: - PokemonListDecoratorMapperImpl

/// Implementation of PokemonListDecoratorMapper.
/// Pure data transformation — no actor isolation needed.
struct PokemonListDecoratorMapperImpl: PokemonListDecoratorMapper {
    // MARK: - Public Methods

    func map(_ model: PokemonListModel) -> PokemonListItemDecorator {
        PokemonListItemDecorator(id: String(model.id),
                                 numericId: model.id,
                                 name: model.name.capitalized,
                                 imageURL: model.imageURL,
                                 types: model.types.map { mapType($0) })
    }

    func mapToItems(_ models: [PokemonListModel]) -> [PokemonListItemDecorator] {
        models.map { map($0) }
    }
}

// MARK: - Private

private extension PokemonListDecoratorMapperImpl {
    func mapType(_ type: PokemonType) -> PokemonTypeDecorator {
        PokemonTypeDecorator(id: type.rawValue,
                             name: type.rawValue.capitalized,
                             typeColor: mapTypeColor(type))
    }

    // swiftlint:disable:next cyclomatic_complexity
    func mapTypeColor(_ type: PokemonType) -> PokemonTypeColor {
        switch type {
        case .normal: .normal
        case .fire: .fire
        case .water: .water
        case .grass: .grass
        case .electric: .electric
        case .ice: .ice
        case .fighting: .fighting
        case .poison: .poison
        case .ground: .ground
        case .flying: .flying
        case .psychic: .psychic
        case .bug: .bug
        case .rock: .rock
        case .ghost: .ghost
        case .dragon: .dragon
        case .dark: .dark
        case .steel: .steel
        case .fairy: .fairy
        case .unknown: .unknown
        }
    }
}
