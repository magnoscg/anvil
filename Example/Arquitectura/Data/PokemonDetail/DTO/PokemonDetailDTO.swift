import Foundation

// MARK: - PokemonDetailDTO

/// Data Transfer Object for Pokemon detail from PokeAPI.
/// Matches the structure of: GET https://pokeapi.co/api/v2/pokemon/{id}
/// Contains full detail fields including stats, abilities, height, and weight.
struct PokemonDetailDTO: Equatable {
    // MARK: - Properties

    /// The Pokemon's unique identifier.
    let id: Int

    /// The Pokemon's name (e.g., "pikachu").
    let name: String

    /// The Pokemon's height in decimeters.
    let height: Int

    /// The Pokemon's weight in hectograms.
    let weight: Int

    /// Array of base stats (HP, Attack, Defense, etc.).
    let stats: [StatSlotDTO]

    /// Array of abilities the Pokemon can have.
    let abilities: [AbilitySlotDTO]

    /// Array of Pokemon types with slot information.
    let types: [TypeSlotDTO]

    /// Sprite URLs for Pokemon images.
    let sprites: SpritesDTO

    /// Reference to species data (contains URL only).
    let species: SpeciesReferenceDTO
}

// MARK: - PokemonDetailDTO + Codable

extension PokemonDetailDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        height = try container.decode(Int.self, forKey: .height)
        weight = try container.decode(Int.self, forKey: .weight)
        stats = try container.decode([StatSlotDTO].self, forKey: .stats)
        abilities = try container.decode([AbilitySlotDTO].self, forKey: .abilities)
        types = try container.decode([TypeSlotDTO].self, forKey: .types)
        sprites = try container.decode(SpritesDTO.self, forKey: .sprites)
        species = try container.decode(SpeciesReferenceDTO.self, forKey: .species)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, height, weight, stats, abilities, types, sprites, species
    }
}

// MARK: - PokemonDetailDTO + Best Image URL

extension PokemonDetailDTO {
    /// Returns the best available image URL, preferring official artwork.
    nonisolated var bestImageURL: String? {
        sprites.other?.officialArtwork?.frontDefault ?? sprites.frontDefault
    }
}

// MARK: - StatSlotDTO

/// Represents a base stat entry for a Pokemon.
struct StatSlotDTO: Equatable {
    // MARK: - Properties

    /// The base stat value.
    let baseStat: Int

    /// The stat reference (name).
    let stat: StatDTO
}

// MARK: - StatSlotDTO + Codable

extension StatSlotDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseStat = try container.decode(Int.self, forKey: .baseStat)
        stat = try container.decode(StatDTO.self, forKey: .stat)
    }

    enum CodingKeys: String, CodingKey {
        case baseStat = "base_stat"
        case stat
    }
}

// MARK: - StatDTO

/// Represents a stat reference containing the stat name.
struct StatDTO: Equatable {
    // MARK: - Properties

    /// The stat name (e.g., "hp", "attack", "defense").
    let name: String
}

// MARK: - StatDTO + Codable

extension StatDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
    }

    enum CodingKeys: String, CodingKey {
        case name
    }
}

// MARK: - AbilitySlotDTO

/// Represents an ability slot for a Pokemon.
struct AbilitySlotDTO: Equatable {
    // MARK: - Properties

    /// The ability reference.
    let ability: AbilityDTO

    /// Whether this is a hidden ability.
    let isHidden: Bool

    /// The ability slot number.
    let slot: Int
}

// MARK: - AbilitySlotDTO + Codable

extension AbilitySlotDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ability = try container.decode(AbilityDTO.self, forKey: .ability)
        isHidden = try container.decode(Bool.self, forKey: .isHidden)
        slot = try container.decode(Int.self, forKey: .slot)
    }

    enum CodingKeys: String, CodingKey {
        case ability
        case isHidden = "is_hidden"
        case slot
    }
}

// MARK: - AbilityDTO

/// Represents an ability reference containing the ability name.
struct AbilityDTO: Equatable {
    // MARK: - Properties

    /// The ability name (e.g., "static", "lightning-rod").
    let name: String
}

// MARK: - AbilityDTO + Codable

extension AbilityDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
    }

    enum CodingKeys: String, CodingKey {
        case name
    }
}

// MARK: - SpeciesReferenceDTO

/// Reference to a Pokemon species resource (URL only, not full content).
struct SpeciesReferenceDTO: Equatable {
    // MARK: - Properties

    /// The URL to the species resource.
    let url: String
}

// MARK: - SpeciesReferenceDTO + Codable

extension SpeciesReferenceDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(String.self, forKey: .url)
    }

    enum CodingKeys: String, CodingKey {
        case url
    }
}
