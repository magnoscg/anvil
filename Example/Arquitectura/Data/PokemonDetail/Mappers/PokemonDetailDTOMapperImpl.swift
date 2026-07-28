import Foundation

// MARK: - PokemonDetailDTOMapperImpl

/// Implementation of PokemonDetailDTOMapper that transforms API DTOs to domain models.
/// Handles species data filtering by language and flavor text cleanup.
struct PokemonDetailDTOMapperImpl: PokemonDetailDTOMapper {
    // MARK: - PokemonDetailDTOMapper

    nonisolated func map(detailDTO: PokemonDetailDTO, speciesDTO: PokemonSpeciesDTO?) -> PokemonDetailModel {
        PokemonDetailModel(id: detailDTO.id,
                           name: formatName(detailDTO.name),
                           imageURL: mapImageURL(from: detailDTO),
                           types: mapTypes(from: detailDTO.types),
                           height: detailDTO.height,
                           weight: detailDTO.weight,
                           stats: mapStats(from: detailDTO.stats),
                           abilities: mapAbilities(from: detailDTO.abilities),
                           description: mapDescription(from: speciesDTO),
                           genus: mapGenus(from: speciesDTO))
    }

    // MARK: - Private Methods

    /// Formats the Pokemon name with proper capitalization.
    private nonisolated func formatName(_ name: String) -> String {
        name.capitalized
    }

    /// Extracts the best available image URL from sprites.
    private nonisolated func mapImageURL(from dto: PokemonDetailDTO) -> URL? {
        guard let urlString = dto.bestImageURL else { return nil }
        return URL(string: urlString)
    }

    /// Maps type slot DTOs to domain type enum values, sorted by slot.
    private nonisolated func mapTypes(from typeSlots: [TypeSlotDTO]) -> [PokemonType] {
        typeSlots
            .sorted { $0.slot < $1.slot }
            .map { PokemonType(from: $0.type.name) }
    }

    /// Maps stat slot DTOs to domain stat models.
    private nonisolated func mapStats(from statSlots: [StatSlotDTO]) -> [PokemonStatModel] {
        statSlots.map { slot in
            PokemonStatModel(name: slot.stat.name, baseStat: slot.baseStat)
        }
    }

    /// Maps ability slot DTOs to domain ability models.
    private nonisolated func mapAbilities(from abilitySlots: [AbilitySlotDTO]) -> [PokemonAbilityModel] {
        abilitySlots
            .sorted { $0.slot < $1.slot }
            .map { slot in
                PokemonAbilityModel(name: slot.ability.name, isHidden: slot.isHidden)
            }
    }

    /// Extracts and cleans the English flavor text description from species data.
    /// Returns nil if species data is unavailable or no English entry exists.
    private nonisolated func mapDescription(from speciesDTO: PokemonSpeciesDTO?) -> String? {
        guard let speciesDTO else { return nil }

        guard let entry = speciesDTO.flavorTextEntries.first(where: { $0.language.name == "en" }) else {
            return nil
        }

        return cleanFlavorText(entry.flavorText)
    }

    /// Extracts the English genus from species data.
    /// Returns nil if species data is unavailable or no English entry exists.
    private nonisolated func mapGenus(from speciesDTO: PokemonSpeciesDTO?) -> String? {
        guard let speciesDTO else { return nil }
        return speciesDTO.genera.first(where: { $0.language.name == "en" })?.genus
    }

    /// Cleans flavor text by replacing control characters with spaces and trimming whitespace.
    /// PokeAPI flavor text contains \n, \f, and \r characters that must be cleaned.
    private nonisolated func cleanFlavorText(_ text: String) -> String {
        // Single-pass: replace control characters with regex, then collapse whitespace
        text
            .replacingOccurrences(of: "[\\n\\r\\u{000C}]", with: " ", options: .regularExpression)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
