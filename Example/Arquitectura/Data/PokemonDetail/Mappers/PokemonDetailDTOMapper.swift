import Foundation

// MARK: - PokemonDetailDTOMapper

/// Protocol for mapping Pokemon detail DTOs to domain models.
/// Handles combining detail and species DTOs with partial failure support.
protocol PokemonDetailDTOMapper: Sendable {
    /// Maps detail and species DTOs to a domain model.
    /// - Parameters:
    ///   - detailDTO: The Pokemon detail DTO (required).
    ///   - speciesDTO: The Pokemon species DTO (optional, nil if fetch failed).
    /// - Returns: A PokemonDetailModel with all available data.
    nonisolated func map(detailDTO: PokemonDetailDTO, speciesDTO: PokemonSpeciesDTO?) -> PokemonDetailModel
}
