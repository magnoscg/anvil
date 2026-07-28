import Foundation

// MARK: - PokemonDetailRemoteDataSourceImpl

/// Implementation of PokemonDetailRemoteDataSource that fetches data from PokeAPI.
/// Uses the unified APIClient with PokeAPIEndpoint for all requests.
struct PokemonDetailRemoteDataSourceImpl: PokemonDetailRemoteDataSource {
    // MARK: - Properties

    private let apiClient: APIClient

    // MARK: - Init

    /// Creates a remote data source with the given API client.
    /// - Parameter apiClient: The unified API client to use for network requests.
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - PokemonDetailRemoteDataSource

    func fetchPokemonDetail(id: Int) async throws -> PokemonDetailDTO {
        let endpoint = PokeAPIEndpoint.pokemonDetail(id: id)
        return try await apiClient.request(endpoint)
    }

    func fetchPokemonSpecies(id: Int) async throws -> PokemonSpeciesDTO {
        let endpoint = PokeAPIEndpoint.pokemonSpecies(id: id)
        return try await apiClient.request(endpoint)
    }
}
