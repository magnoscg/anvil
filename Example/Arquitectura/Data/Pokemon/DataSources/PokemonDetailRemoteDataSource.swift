import Foundation

// MARK: - PokemonDetailRemoteDataSource

/// Protocol for fetching Pokemon detail and species data from the remote PokeAPI.
protocol PokemonDetailRemoteDataSource: Sendable {
    /// Fetches detailed information for a specific Pokemon.
    /// - Parameter id: The Pokemon's unique identifier.
    /// - Returns: Pokemon detail DTO with stats, abilities, types, and sprites.
    /// - Throws: APIError if the request fails.
    func fetchPokemonDetail(id: Int) async throws -> PokemonDetailDTO

    /// Fetches species information for a specific Pokemon.
    /// - Parameter id: The Pokemon's unique identifier.
    /// - Returns: Pokemon species DTO with flavor text and genera.
    /// - Throws: APIError if the request fails.
    func fetchPokemonSpecies(id: Int) async throws -> PokemonSpeciesDTO
}
