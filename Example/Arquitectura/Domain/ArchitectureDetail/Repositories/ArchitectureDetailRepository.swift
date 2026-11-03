import Foundation

// MARK: - ArchitectureDetailRepository

/// Protocol for accessing architecture feature detail data
protocol ArchitectureDetailRepository: Sendable {
    /// Gets the detailed information for a specific feature
    /// - Parameter id: The feature ID
    /// - Returns: The feature detail model if found, nil otherwise
    /// - Throws: Error if data loading fails
    func getFeatureDetail(id: String) async throws -> ArchitectureDetailModel?
}
