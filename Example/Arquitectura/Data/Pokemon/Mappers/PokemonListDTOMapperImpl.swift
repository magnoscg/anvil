import Foundation

// MARK: - PokemonListDTOMapperImpl

/// Implementation of PokemonListDTOMapper that transforms API DTOs to domain models.
/// All methods are `nonisolated` for use from any actor context (Swift 6 MainActor mode).
struct PokemonListDTOMapperImpl: PokemonListDTOMapper {
    // MARK: - PokemonListDTOMapper

    nonisolated func mapToDomain(_ dto: PokemonListDTO) -> PokemonListModel {
        PokemonListModel(id: dto.id,
                         name: formatName(dto.name),
                         imageURL: mapImageURL(from: dto),
                         types: mapTypes(from: dto.types))
    }

    nonisolated func mapToDomain(_ dtos: [PokemonListDTO]) -> [PokemonListModel] {
        dtos.map { mapToDomain($0) }
    }

    // MARK: - Private Methods

    /// Formats the Pokemon name with proper capitalization.
    /// - Parameter name: Raw name from API (e.g., "pikachu").
    /// - Returns: Formatted name (e.g., "Pikachu").
    private nonisolated func formatName(_ name: String) -> String {
        name.capitalized
    }

    /// Extracts the best available image URL from sprites.
    /// Prefers official artwork over default sprite.
    /// - Parameter dto: The Pokemon DTO with sprite information.
    /// - Returns: URL for the Pokemon image, or nil if unavailable.
    private nonisolated func mapImageURL(from dto: PokemonListDTO) -> URL? {
        guard let urlString = dto.bestImageURL else { return nil }
        return URL(string: urlString)
    }

    /// Maps type slot DTOs to domain type enum values.
    /// Types are sorted by slot number (primary type first).
    /// - Parameter typeSlots: Array of type slot DTOs from the API.
    /// - Returns: Array of PokemonType enum values.
    private nonisolated func mapTypes(from typeSlots: [TypeSlotDTO]) -> [PokemonType] {
        typeSlots
            .sorted { $0.slot < $1.slot }
            .map { PokemonType(from: $0.type.name) }
    }
}
