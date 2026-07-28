import Foundation

// MARK: - PokemonDetailDecoratorMapperImpl

/// Implementation of PokemonDetailDecoratorMapper.
/// Pure data transformation — no actor isolation needed.
struct PokemonDetailDecoratorMapperImpl: PokemonDetailDecoratorMapper {
    // MARK: - Public Methods

    func map(_ model: PokemonDetailModel) -> PokemonDetailPageDecorator {
        PokemonDetailPageDecorator(id: String(model.id),
                                   name: model.name.capitalized,
                                   formattedId: String(format: "#%03d", model.id),
                                   imageURL: model.imageURL,
                                   types: model.types.map { mapType($0) },
                                   genus: model.genus,
                                   description: model.description,
                                   height: formatHeight(model.height),
                                   weight: formatWeight(model.weight),
                                   abilities: model.abilities.map { mapAbility($0) },
                                   stats: model.stats.map { mapStat($0) })
    }
}

// MARK: - Private

private extension PokemonDetailDecoratorMapperImpl {
    func formatHeight(_ decimeters: Int) -> String {
        let meters = Double(decimeters) / 10.0
        return String(format: "%.1f m", meters)
    }

    func formatWeight(_ hectograms: Int) -> String {
        let kilograms = Double(hectograms) / 10.0
        return String(format: "%.1f kg", kilograms)
    }

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

    func mapAbility(_ ability: PokemonAbilityModel) -> PokemonAbilityDecorator {
        PokemonAbilityDecorator(id: ability.name,
                                name: ability.name.replacingOccurrences(of: "-", with: " ").capitalized,
                                isHidden: ability.isHidden)
    }

    func mapStat(_ stat: PokemonStatModel) -> PokemonStatDecorator {
        PokemonStatDecorator(id: stat.name,
                             name: mapStatDisplayName(stat.name),
                             value: stat.baseStat,
                             progress: Double(stat.baseStat) / 255.0)
    }

    func mapStatDisplayName(_ name: String) -> String {
        switch name {
        case "hp": "HP"
        case "attack": "ATK"
        case "defense": "DEF"
        case "special-attack": "SpA"
        case "special-defense": "SpD"
        case "speed": "SPD"
        default: name.capitalized
        }
    }
}
