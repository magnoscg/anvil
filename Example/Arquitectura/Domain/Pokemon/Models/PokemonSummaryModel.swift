import Foundation

// MARK: - PokemonSummaryModel

/// Summary of a Pokemon: the fields needed wherever a Pokemon is listed or referenced
/// (id, name, artwork and types). `PokemonDetailModel` holds the full profile.
struct PokemonSummaryModel: Equatable, Identifiable {
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
