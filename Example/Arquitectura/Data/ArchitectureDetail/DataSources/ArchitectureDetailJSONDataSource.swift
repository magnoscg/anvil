import Foundation

// MARK: - ArchitectureDetailJSONDataSource

/// Protocol for loading architecture detail data from JSON
protocol ArchitectureDetailJSONDataSource: Sendable {
    /// Loads all feature details from the bundled JSON file
    /// - Returns: Array of ArchitectureDetailDTO
    /// - Throws: `DataSourceError.fileNotFound` if the file is missing, or the `DecodingError` if it is invalid
    func loadFeatureDetails() async throws -> [ArchitectureDetailDTO]

    /// Loads a specific feature detail by ID
    /// - Parameter id: The feature ID to find
    /// - Returns: The ArchitectureDetailDTO if found, nil otherwise
    /// - Throws: `DataSourceError.fileNotFound` if the file is missing, or the `DecodingError` if it is invalid
    func loadFeatureDetail(id: String) async throws -> ArchitectureDetailDTO?
}

// MARK: - DataSourceError

nonisolated enum DataSourceError: Error {
    case fileNotFound(String)
    case decodingFailed(String)
}
