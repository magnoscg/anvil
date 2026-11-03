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
