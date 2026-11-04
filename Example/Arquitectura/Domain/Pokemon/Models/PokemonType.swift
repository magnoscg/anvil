import Foundation

// MARK: - PokemonType

/// Represents all 18 Pokemon types as defined in the games.
/// Shared by every Pokemon model (summary and detail) and used for filtering, sorting, and UI color mapping.
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
