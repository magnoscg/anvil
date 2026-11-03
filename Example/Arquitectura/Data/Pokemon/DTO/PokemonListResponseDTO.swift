import Foundation

// MARK: - PokemonListResponseDTO

/// Data Transfer Object for the paginated Pokemon list response from PokeAPI.
/// Matches the structure of: GET https://pokeapi.co/api/v2/pokemon?limit=20&offset=0
struct PokemonListResponseDTO: Equatable {
    // MARK: - Properties

    /// Total number of Pokemon available in the API.
    let count: Int

    /// URL for the next page of results, or nil if on the last page.
    let next: String?

    /// URL for the previous page of results, or nil if on the first page.
    let previous: String?

    /// Array of Pokemon name/URL pairs for this page.
    let results: [PokemonListResultDTO]
}

// MARK: - PokemonListResponseDTO + Codable

extension PokemonListResponseDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = try container.decode(Int.self, forKey: .count)
        next = try container.decodeIfPresent(String.self, forKey: .next)
        previous = try container.decodeIfPresent(String.self, forKey: .previous)
        results = try container.decode([PokemonListResultDTO].self, forKey: .results)
    }

    enum CodingKeys: String, CodingKey {
        case count, next, previous, results
    }
}

// MARK: - PokemonListResultDTO

/// Individual Pokemon entry from the list response.
/// Contains minimal data; full details require a separate API call.
struct PokemonListResultDTO: Equatable {
    // MARK: - Properties

    /// The Pokemon name (e.g., "pikachu").
    let name: String

    /// URL to fetch full Pokemon details (e.g., "https://pokeapi.co/api/v2/pokemon/25/").
    let url: String
}

// MARK: - PokemonListResultDTO + Codable

extension PokemonListResultDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(String.self, forKey: .url)
    }

    enum CodingKeys: String, CodingKey {
        case name, url
    }
}

// MARK: - PokemonListResultDTO + ID Extraction

extension PokemonListResultDTO {
    /// Extracts the Pokemon ID from the URL.
    /// Example: "https://pokeapi.co/api/v2/pokemon/25/" -> 25
    /// - Returns: The Pokemon ID, or nil if extraction fails.
    var extractedID: Int? {
        // URL format: https://pokeapi.co/api/v2/pokemon/{id}/
        let components = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .components(separatedBy: "/")
        guard let lastComponent = components.last else { return nil }
        return Int(lastComponent)
    }
}
