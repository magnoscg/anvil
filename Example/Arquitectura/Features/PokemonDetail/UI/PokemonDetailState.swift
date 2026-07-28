import Foundation

// MARK: - PokemonDetailState

/// State enum for the PokemonDetail feature screen
enum PokemonDetailState: Equatable {
    case idle
    case loading
    case loaded(PokemonDetailPageDecorator)
    case error(ErrorDecorator)
}
