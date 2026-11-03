import Foundation

// MARK: - ArchitectureRepository

/// Repository protocol for architecture features, owned by Domain.
/// Implementations throw only `DomainError` or `CancellationError`; wrap any data source that can
/// fail in `DomainError.catching` (the current static data source cannot fail).
protocol ArchitectureRepository: Sendable {
    /// Gets all architecture features
    /// - Returns: Array of architecture models
    func getFeatures() async throws -> [ArchitectureModel]

    /// Gets a specific architecture feature by ID
    /// - Parameter id: The feature ID
    /// - Returns: The architecture model if found, nil otherwise
    func getFeature(id: String) async throws -> ArchitectureModel?
}
