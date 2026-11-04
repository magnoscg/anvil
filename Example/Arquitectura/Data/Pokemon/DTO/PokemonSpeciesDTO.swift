import Foundation

// MARK: - PokemonSpeciesDTO

/// Data Transfer Object for Pokemon species data from PokeAPI.
/// Matches the structure of: GET https://pokeapi.co/api/v2/pokemon-species/{id}
/// Contains flavor text entries and genera for localized descriptions.
struct PokemonSpeciesDTO: Equatable {
    // MARK: - Properties

    /// Array of flavor text entries across games and languages.
    let flavorTextEntries: [FlavorTextEntryDTO]

    /// Array of genera (category names) across languages.
    let genera: [GenusDTO]
}

// MARK: - PokemonSpeciesDTO + Codable

extension PokemonSpeciesDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        flavorTextEntries = try container.decode([FlavorTextEntryDTO].self, forKey: .flavorTextEntries)
        genera = try container.decode([GenusDTO].self, forKey: .genera)
    }

    enum CodingKeys: String, CodingKey {
        case flavorTextEntries = "flavor_text_entries"
        case genera
    }
}

// MARK: - FlavorTextEntryDTO

/// Represents a localized flavor text entry from a specific game version.
struct FlavorTextEntryDTO: Equatable {
    // MARK: - Properties

    /// The flavor text description.
    let flavorText: String

    /// The language of this entry.
    let language: LanguageDTO

    /// The game version this entry is from.
    let version: VersionDTO
}

// MARK: - FlavorTextEntryDTO + Codable

extension FlavorTextEntryDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        flavorText = try container.decode(String.self, forKey: .flavorText)
        language = try container.decode(LanguageDTO.self, forKey: .language)
        version = try container.decode(VersionDTO.self, forKey: .version)
    }

    enum CodingKeys: String, CodingKey {
        case flavorText = "flavor_text"
        case language
        case version
    }
}

// MARK: - GenusDTO

/// Represents a localized genus (category name, e.g., "Mouse Pokémon").
struct GenusDTO: Equatable {
    // MARK: - Properties

    /// The genus text (e.g., "Mouse Pokémon").
    let genus: String

    /// The language of this genus entry.
    let language: LanguageDTO
}

// MARK: - GenusDTO + Codable

extension GenusDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        genus = try container.decode(String.self, forKey: .genus)
        language = try container.decode(LanguageDTO.self, forKey: .language)
    }

    enum CodingKeys: String, CodingKey {
        case genus
        case language
    }
}

// MARK: - LanguageDTO

/// Represents a language reference.
struct LanguageDTO: Equatable {
    // MARK: - Properties

    /// The language name (e.g., "en", "es", "ja").
    let name: String
}

// MARK: - LanguageDTO + Codable

extension LanguageDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
    }

    enum CodingKeys: String, CodingKey {
        case name
    }
}

// MARK: - VersionDTO

/// Represents a game version reference.
struct VersionDTO: Equatable {
    // MARK: - Properties

    /// The version name (e.g., "red", "blue", "sword").
    let name: String
}

// MARK: - VersionDTO + Codable

extension VersionDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
    }

    enum CodingKeys: String, CodingKey {
        case name
    }
}
