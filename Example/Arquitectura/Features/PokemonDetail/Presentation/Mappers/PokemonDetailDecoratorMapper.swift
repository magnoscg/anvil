import Foundation

// MARK: - PokemonDetailDecoratorMapper

/// Protocol for mapping PokemonDetail domain model to UI decorator.
/// Pure data transformation — no actor isolation needed.
protocol PokemonDetailDecoratorMapper: Sendable {
    /// Maps a PokemonDetailModel to a PokemonDetailPageDecorator for UI display
    /// - Parameter model: The domain model to map
    /// - Returns: The mapped page decorator with formatted values
    func map(_ model: PokemonDetailModel) -> PokemonDetailPageDecorator
}
