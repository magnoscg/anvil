import Foundation

// MARK: - PokemonListUseCase

/// Protocol for fetching a paginated list of Pokemon.
/// Abstracts pagination details from the presentation layer.
protocol PokemonListUseCase: Sendable {
    /// Fetches a page of Pokemon.
    /// - Parameters:
    ///   - page: Zero-based page index.
    ///   - pageSize: Number of Pokemon per page.
    /// - Returns: Result containing Pokemon and pagination info.
    /// - Throws: Error if the fetch fails.
    func execute(page: Int, pageSize: Int) async throws -> PokemonListResult
}

// MARK: - PokemonListResult

/// Result type for Pokemon list use case.
/// Contains the list of Pokemon and pagination state.
struct PokemonListResult: Equatable {
    // MARK: - Properties

    /// The fetched Pokemon models for this page.
    let pokemon: [PokemonListModel]

    /// Whether there are more pages available.
    let hasMore: Bool

    /// Total count of Pokemon available in the API.
    let totalCount: Int
}
