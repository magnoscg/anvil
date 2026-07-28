import Foundation

// MARK: - PokemonListState

/// State enum for the PokemonList feature screen
enum PokemonListState: Equatable {
    case idle
    case loading
    case loaded([PokemonListItemDecorator])
    case error(ErrorDecorator)
}
