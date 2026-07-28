import Foundation

// MARK: - PokemonListDecoratorMapper

/// Protocol for mapping PokemonList domain models to UI decorators.
/// Pure data transformation — no actor isolation needed.
protocol PokemonListDecoratorMapper: Sendable {
    /// Maps a single domain model to a UI decorator
    /// - Parameter model: The domain model to map
    /// - Returns: The mapped UI decorator
    func map(_ model: PokemonListModel) -> PokemonListItemDecorator

    /// Maps an array of domain models to UI decorators
    /// - Parameter models: The domain models to map
    /// - Returns: Array of item decorators
    func mapToItems(_ models: [PokemonListModel]) -> [PokemonListItemDecorator]
}
