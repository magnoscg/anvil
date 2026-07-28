import Foundation

// MARK: - PokemonListRemoteDataSource

/// Protocol for fetching Pokemon data from the remote PokeAPI.
protocol PokemonListRemoteDataSource: Sendable {
    /// Fetches a paginated list of Pokemon.
    /// - Parameters:
    ///   - limit: Maximum number of Pokemon to fetch per page.
    ///   - offset: Starting index for pagination.
    /// - Returns: Paginated response containing Pokemon names and URLs.
    /// - Throws: APIError if the request fails.
    func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponseDTO

    /// Fetches detailed information for a specific Pokemon.
    /// - Parameter id: The Pokemon's unique identifier.
    /// - Returns: Pokemon detail DTO with types and sprites.
    /// - Throws: APIError if the request fails.
    func fetchPokemonDetail(id: Int) async throws -> PokemonListDTO
}
