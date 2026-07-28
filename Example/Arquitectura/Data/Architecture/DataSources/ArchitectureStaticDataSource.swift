import Foundation

// MARK: - ArchitectureStaticDataSource

/// DataSource for static architecture feature data.
/// Used when data is hardcoded/embedded rather than fetched from API or persistence.
protocol ArchitectureStaticDataSource: Sendable {
    /// Returns all architecture features as domain models
    func getFeatures() -> [ArchitectureModel]

    /// Returns a specific feature by ID
    func getFeature(id: String) -> ArchitectureModel?
}
