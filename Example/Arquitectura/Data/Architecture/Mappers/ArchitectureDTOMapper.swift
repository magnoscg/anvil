import Foundation

// MARK: - ArchitectureDTOMapper

/// Protocol for mapping DTO to Domain model.
/// Must be Sendable for Swift 6 strict concurrency.
protocol ArchitectureDTOMapper: Sendable {
    /// Maps a DTO to a domain model
    /// - Parameter dto: The DTO to map
    /// - Returns: The mapped domain model
    func map(_ dto: ArchitectureDTO) -> ArchitectureModel

    /// Maps an array of DTOs to domain models
    /// - Parameter dtos: The DTOs to map
    /// - Returns: The mapped domain models
    func map(_ dtos: [ArchitectureDTO]) -> [ArchitectureModel]
}
