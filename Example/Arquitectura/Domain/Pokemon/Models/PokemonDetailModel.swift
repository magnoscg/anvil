import Foundation

// MARK: - PokemonDetailModel

/// Domain model representing the full detail of a Pokemon.
/// Contains all information needed for the Pokédex detail screen.
struct PokemonDetailModel: Equatable, Identifiable {
    // MARK: - Properties

    /// The Pokemon's unique identifier.
    let id: Int

    /// The Pokemon's display name.
    let name: String

    /// URL for the Pokemon's official artwork image.
    let imageURL: URL?

    /// Array of Pokemon types (e.g., [.electric] for Pikachu).
    let types: [PokemonType]

    /// The Pokemon's height in decimeters (raw API value).
    let height: Int

    /// The Pokemon's weight in hectograms (raw API value).
    let weight: Int

    /// Array of base stats (HP, Attack, Defense, etc.).
    let stats: [PokemonStatModel]

    /// Array of abilities the Pokemon can have.
    let abilities: [PokemonAbilityModel]

    /// Cleaned flavor text description in English, nil if unavailable.
    let description: String?

    /// Pokemon category/genus in English (e.g., "Mouse Pokémon"), nil if unavailable.
    let genus: String?
}

// MARK: - PokemonStatModel

/// Domain model representing a single base stat.
struct PokemonStatModel: Equatable, Identifiable {
    // MARK: - Properties

    /// Unique identifier derived from the stat name.
    var id: String {
        name
    }

    /// The stat name (e.g., "hp", "attack", "defense").
    let name: String

    /// The base stat value.
    let baseStat: Int
}

// MARK: - PokemonAbilityModel

/// Domain model representing a Pokemon ability.
struct PokemonAbilityModel: Equatable, Identifiable {
    // MARK: - Properties

    /// Unique identifier derived from the ability name.
    var id: String {
        name
    }

    /// The ability name (e.g., "static", "lightning-rod").
    let name: String

    /// Whether this is a hidden ability.
    let isHidden: Bool
}
