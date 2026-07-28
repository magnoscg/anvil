import Foundation

// MARK: - PokemonListDTOMapper

/// Protocol for mapping Pokemon DTOs to domain models.
/// Methods are `nonisolated` to allow calling from any actor context.
protocol PokemonListDTOMapper: Sendable {
    /// Maps a Pokemon detail DTO to a domain model.
    /// - Parameter dto: The Pokemon detail DTO from the API.
    /// - Returns: A domain model representing the Pokemon.
    nonisolated func mapToDomain(_ dto: PokemonListDTO) -> PokemonListModel

    /// Maps an array of Pokemon detail DTOs to domain models.
    /// - Parameter dtos: Array of Pokemon detail DTOs.
    /// - Returns: Array of domain models.
    nonisolated func mapToDomain(_ dtos: [PokemonListDTO]) -> [PokemonListModel]
}
