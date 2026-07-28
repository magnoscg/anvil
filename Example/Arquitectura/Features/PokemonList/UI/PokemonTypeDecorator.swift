import Foundation

// MARK: - PokemonTypeDecorator

/// Decorator representing a Pokemon type badge for UI display.
struct PokemonTypeDecorator: Equatable, Identifiable {
    // MARK: - Properties

    let id: String
    let name: String
    let typeColor: PokemonTypeColor
}

// MARK: - PokemonTypeColor

/// UI color mapping for all Pokemon types plus an unknown fallback.
enum PokemonTypeColor: Equatable {
    case normal
    case fire
    case water
    case grass
    case electric
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
}
