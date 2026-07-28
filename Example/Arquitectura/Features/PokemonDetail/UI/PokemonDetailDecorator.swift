import Foundation

// MARK: - PokemonDetailPageDecorator

/// Decorator representing the complete Pokemon detail page for UI display
struct PokemonDetailPageDecorator: Equatable, Identifiable {
    // MARK: - Properties

    let id: String
    let name: String
    let formattedId: String
    let imageURL: URL?
    let types: [PokemonTypeDecorator]
    let genus: String?
    let description: String?
    let height: String
    let weight: String
    let abilities: [PokemonAbilityDecorator]
    let stats: [PokemonStatDecorator]

    // MARK: - Computed Properties

    var baseStatTotal: Int {
        stats.reduce(0) { $0 + $1.value }
    }

    var primaryTypeColor: PokemonTypeColor? {
        types.first?.typeColor
    }
}

// MARK: - PokemonAbilityDecorator

/// Decorator representing a Pokemon ability for UI display
struct PokemonAbilityDecorator: Equatable, Identifiable {
    // MARK: - Properties

    let id: String
    let name: String
    let isHidden: Bool
}

// MARK: - PokemonStatDecorator

/// Decorator representing a Pokemon base stat for UI display
struct PokemonStatDecorator: Equatable, Identifiable {
    // MARK: - Properties

    let id: String
    let name: String
    let value: Int
    let progress: Double
}
