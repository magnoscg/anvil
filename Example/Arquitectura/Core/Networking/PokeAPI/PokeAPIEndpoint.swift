import Foundation

// MARK: - PokeAPIEndpoint

/// Represents an endpoint for the PokeAPI.
/// Contains all the information needed to build a URLRequest for PokeAPI calls.
/// Conforms to APIEndpoint protocol for unified client usage.
struct PokeAPIEndpoint: APIEndpoint {
    // MARK: - Constants

    /// Base URL for the PokeAPI (static for convenience)
    private static let pokeAPIBaseURL: URL = {
        guard let url = URL(string: "https://pokeapi.co/api/v2") else {
            fatalError("Invalid PokeAPI base URL constant")
        }
        return url
    }()

    // MARK: - APIEndpoint Properties

    /// Base URL for this endpoint (required by APIEndpoint protocol)
    var baseURL: URL {
        Self.pokeAPIBaseURL
    }

    /// The path component of the URL (e.g., "/pokemon", "/pokemon/25")
    let path: String

    /// Query parameters to append to the URL
    let queryParameters: [String: any CustomStringConvertible & Sendable]?

    // MARK: - Init

    private init(path: String,
                 queryParameters: [String: any CustomStringConvertible & Sendable]? = nil) {
        self.path = path
        self.queryParameters = queryParameters
    }

    // Note: buildRequest() is provided by APIEndpoint protocol extension
}

// MARK: - Factory Methods

extension PokeAPIEndpoint {
    /// Creates an endpoint for fetching the Pokemon list.
    /// - Parameters:
    ///   - limit: Maximum number of Pokemon to fetch.
    ///   - offset: Starting index for pagination.
    /// - Returns: A configured endpoint for the Pokemon list.
    static func pokemonList(limit: Int, offset: Int) -> PokeAPIEndpoint {
        PokeAPIEndpoint(path: "/pokemon",
                        queryParameters: ["limit": limit, "offset": offset])
    }

    /// Creates an endpoint for fetching Pokemon details by ID.
    /// - Parameter id: The Pokemon ID.
    /// - Returns: A configured endpoint for the Pokemon detail.
    static func pokemonDetail(id: Int) -> PokeAPIEndpoint {
        PokeAPIEndpoint(path: "/pokemon/\(id)")
    }

    /// Creates an endpoint for fetching Pokemon details by name.
    /// - Parameter name: The Pokemon name.
    /// - Returns: A configured endpoint for the Pokemon detail.
    static func pokemonDetail(name: String) -> PokeAPIEndpoint {
        PokeAPIEndpoint(path: "/pokemon/\(name.lowercased())")
    }

    /// Creates an endpoint for fetching Pokemon species metadata by ID.
    /// - Parameter id: The Pokemon ID.
    /// - Returns: A configured endpoint for the Pokemon species detail.
    static func pokemonSpecies(id: Int) -> PokeAPIEndpoint {
        PokeAPIEndpoint(path: "/pokemon-species/\(id)")
    }
}
