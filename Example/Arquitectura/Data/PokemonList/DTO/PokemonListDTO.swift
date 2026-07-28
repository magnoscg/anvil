import Foundation

// MARK: - PokemonListDTO

/// Data Transfer Object for Pokemon detail from PokeAPI.
/// Matches the structure of: GET https://pokeapi.co/api/v2/pokemon/{id}
/// Only includes fields needed for the list display.
struct PokemonListDTO: Equatable {
    // MARK: - Properties

    /// The Pokemon's unique identifier.
    let id: Int

    /// The Pokemon's name (e.g., "pikachu").
    let name: String

    /// Array of Pokemon types with slot information.
    let types: [TypeSlotDTO]

    /// Sprite URLs for Pokemon images.
    let sprites: SpritesDTO
}

// MARK: - PokemonListDTO + Codable

extension PokemonListDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        types = try container.decode([TypeSlotDTO].self, forKey: .types)
        sprites = try container.decode(SpritesDTO.self, forKey: .sprites)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, types, sprites
    }
}

// MARK: - TypeSlotDTO

/// Represents a type slot for a Pokemon.
/// Pokemon can have 1-2 types, each with a slot number.
struct TypeSlotDTO: Equatable {
    // MARK: - Properties

    /// The slot number (1 for primary type, 2 for secondary type).
    let slot: Int

    /// The type information.
    let type: TypeDTO
}

// MARK: - TypeSlotDTO + Codable

extension TypeSlotDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        slot = try container.decode(Int.self, forKey: .slot)
        type = try container.decode(TypeDTO.self, forKey: .type)
    }

    enum CodingKeys: String, CodingKey {
        case slot, type
    }
}

// MARK: - TypeDTO

/// Represents a Pokemon type reference.
struct TypeDTO: Equatable {
    // MARK: - Properties

    /// The type name (e.g., "electric", "fire", "water").
    let name: String
}

// MARK: - TypeDTO + Codable

extension TypeDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
    }

    enum CodingKeys: String, CodingKey {
        case name
    }
}

// MARK: - SpritesDTO

/// Contains URLs to Pokemon sprite images.
struct SpritesDTO: Equatable {
    // MARK: - Properties

    /// Default front-facing sprite URL.
    let frontDefault: String?

    /// Container for additional sprite versions.
    let other: OtherSpritesDTO?
}

// MARK: - SpritesDTO + Codable

extension SpritesDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        frontDefault = try container.decodeIfPresent(String.self, forKey: .frontDefault)
        other = try container.decodeIfPresent(OtherSpritesDTO.self, forKey: .other)
    }

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
        case other
    }
}

// MARK: - OtherSpritesDTO

/// Container for alternative sprite versions.
struct OtherSpritesDTO: Equatable {
    // MARK: - Properties

    /// Official artwork sprites (higher quality).
    let officialArtwork: OfficialArtworkDTO?
}

// MARK: - OtherSpritesDTO + Codable

extension OtherSpritesDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        officialArtwork = try container.decodeIfPresent(OfficialArtworkDTO.self, forKey: .officialArtwork)
    }

    enum CodingKeys: String, CodingKey {
        case officialArtwork = "official-artwork"
    }
}

// MARK: - OfficialArtworkDTO

/// Contains official artwork sprite URLs.
struct OfficialArtworkDTO: Equatable {
    // MARK: - Properties

    /// Front-facing official artwork URL.
    let frontDefault: String?
}

// MARK: - OfficialArtworkDTO + Codable

extension OfficialArtworkDTO: Codable {
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        frontDefault = try container.decodeIfPresent(String.self, forKey: .frontDefault)
    }

    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

// MARK: - PokemonListDTO + Best Image URL

extension PokemonListDTO {
    /// Returns the best available image URL, preferring official artwork.
    nonisolated var bestImageURL: String? {
        // Prefer official artwork, fallback to default sprite
        sprites.other?.officialArtwork?.frontDefault ?? sprites.frontDefault
    }
}
