import Foundation

// MARK: - ArchitectureDetailDTOMapper

/// Protocol for mapping ArchitectureDetailDTO to ArchitectureDetailModel
protocol ArchitectureDetailDTOMapper: Sendable {
    /// Maps a DTO to a domain model
    /// - Parameter dto: The DTO to map
    /// - Returns: The mapped domain model
    func mapToDomain(_ dto: ArchitectureDetailDTO) -> ArchitectureDetailModel
}
