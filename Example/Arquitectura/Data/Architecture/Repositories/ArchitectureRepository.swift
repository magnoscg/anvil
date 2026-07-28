import Foundation

// MARK: - ArchitectureRepository

/// Repository protocol for architecture features
protocol ArchitectureRepository: Sendable {
    /// Gets all architecture features
    /// - Returns: Array of architecture models
    func getFeatures() async throws -> [ArchitectureModel]

    /// Gets a specific architecture feature by ID
    /// - Parameter id: The feature ID
    /// - Returns: The architecture model if found, nil otherwise
    func getFeature(id: String) async throws -> ArchitectureModel?
}
