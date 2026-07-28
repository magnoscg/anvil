import Foundation

// MARK: - PokemonListModel

/// Domain model representing a Pokemon for list display.
/// Contains essential information for rendering a Pokemon card in a list.
struct PokemonListModel: Equatable, Identifiable {
    // MARK: - Properties

    /// The Pokemon's unique identifier.
    let id: Int

    /// The Pokemon's display name (e.g., "Pikachu").
    let name: String

    /// URL for the Pokemon's image (official artwork or sprite).
    let imageURL: URL?

    /// Array of Pokemon types (e.g., [.electric] for Pikachu, [.fire, .flying] for Charizard).
    let types: [PokemonType]
}

// MARK: - PokemonType

/// Represents all 18 Pokemon types as defined in the games.
/// Used for type-based filtering, sorting, and UI color mapping.
enum PokemonType: String, Equatable, CaseIterable {
    // MARK: - Cases

    case normal
    case fire
    case water
    case electric
    case grass
    case ice
    case fighting
    case poison
    case ground
    case flying
    case psychic
    case bug
    case rock
    case ghost
    case dragon
    case dark
    case steel
    case fairy
    case unknown

    // MARK: - Init from String

    /// Initializes a PokemonType from a string, defaulting to .unknown if not recognized.
    /// - Parameter rawValue: The type name from the API.
    nonisolated init(from string: String) {
        self = PokemonType(rawValue: string.lowercased()) ?? .unknown
    }
}
