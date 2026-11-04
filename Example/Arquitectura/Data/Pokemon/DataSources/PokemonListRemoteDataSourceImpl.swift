import Foundation

// MARK: - PokemonListRemoteDataSourceImpl

/// Implementation of PokemonListRemoteDataSource that fetches data from PokeAPI.
/// Uses the unified APIClient with PokeAPIEndpoint for all requests.
struct PokemonListRemoteDataSourceImpl: PokemonListRemoteDataSource {
    // MARK: - Properties

    private let apiClient: APIClient

    // MARK: - Init

    /// Creates a remote data source with the given API client.
    /// - Parameter apiClient: The unified API client to use for network requests.
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - PokemonListRemoteDataSource

    func fetchPokemonList(limit: Int, offset: Int) async throws -> PokemonListResponseDTO {
        let endpoint = PokeAPIEndpoint.pokemonList(limit: limit, offset: offset)
        return try await apiClient.request(endpoint)
    }

    func fetchPokemonDetail(id: Int) async throws -> PokemonListDTO {
        let endpoint = PokeAPIEndpoint.pokemonDetail(id: id)
        return try await apiClient.request(endpoint)
    }
}
