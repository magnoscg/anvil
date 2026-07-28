import Foundation

// MARK: - PokemonListRepository

/// Protocol for accessing Pokemon list data.
/// Abstracts the data source implementation from the domain layer.
protocol PokemonListRepository: Sendable {
    /// Fetches a list of Pokemon with full details (types, images).
    /// Handles the two-step fetch: list endpoint -> detail endpoints.
    /// - Parameters:
    ///   - limit: Maximum number of Pokemon to fetch.
    ///   - offset: Starting index for pagination.
    /// - Returns: Result containing Pokemon models and pagination info.
    /// - Throws: Error if any network request fails.
    func getPokemonList(limit: Int, offset: Int) async throws -> PokemonListRepositoryResult
}

// MARK: - PokemonListRepositoryResult

/// Result type for Pokemon list fetch operations.
/// Contains the list of Pokemon and pagination metadata.
struct PokemonListRepositoryResult: Equatable {
    // MARK: - Properties

    /// The fetched Pokemon models.
    let pokemon: [PokemonListModel]

    /// Total count of available Pokemon in the API.
    let totalCount: Int

    /// Whether there are more Pokemon to fetch.
    let hasMore: Bool
}
