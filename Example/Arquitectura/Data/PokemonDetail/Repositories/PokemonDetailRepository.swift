import Foundation

// MARK: - PokemonDetailRepository

/// Protocol for accessing Pokemon detail data.
/// Returns domain models directly — callers never see DTOs.
protocol PokemonDetailRepository: Sendable {
    /// Fetches complete Pokemon detail by combining detail and species endpoints.
    /// Species failure is non-fatal (partial failure pattern).
    /// - Parameter id: The Pokemon's unique identifier.
    /// - Returns: A complete PokemonDetailModel with all available data.
    /// - Throws: Error if the required detail endpoint fails. CancellationError is always propagated.
    func fetchPokemonDetail(id: Int) async throws -> PokemonDetailModel
}
