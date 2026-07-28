import Foundation

// MARK: - PokemonListItemDecorator

/// Decorator representing a single Pokemon for list UI display
struct PokemonListItemDecorator: Equatable, Identifiable {
    // MARK: - Properties

    let id: String
    let numericId: Int
    let name: String
    let imageURL: URL?
    let types: [PokemonTypeDecorator]
}
