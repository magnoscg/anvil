import Foundation

// MARK: - PokemonDetailUseCase

/// Protocol for fetching complete Pokemon detail data.
/// Combines data from multiple endpoints into a unified domain model.
protocol PokemonDetailUseCase: Sendable {
    /// Fetches complete detail for a Pokemon by ID.
    /// - Parameter pokemonId: The Pokemon's unique identifier.
    /// - Returns: A complete PokemonDetailModel with all available data.
    /// - Throws: Error if the required detail endpoint fails. Species failure is non-fatal.
    func execute(pokemonId: Int) async throws -> PokemonDetailModel
}
