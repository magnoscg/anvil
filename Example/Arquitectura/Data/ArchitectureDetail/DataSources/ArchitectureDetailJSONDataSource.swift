import Foundation

// MARK: - ArchitectureDetailJSONDataSource

/// Protocol for loading architecture detail data from JSON
protocol ArchitectureDetailJSONDataSource: Sendable {
    /// Loads all feature details from the bundled JSON file
    /// - Returns: Array of ArchitectureDetailDTO
    /// - Throws: DataSourceError if file not found or decoding fails
    func loadFeatureDetails() throws -> [ArchitectureDetailDTO]

    /// Loads a specific feature detail by ID
    /// - Parameter id: The feature ID to find
    /// - Returns: The ArchitectureDetailDTO if found, nil otherwise
    /// - Throws: DataSourceError if file not found or decoding fails
    func loadFeatureDetail(id: String) throws -> ArchitectureDetailDTO?
}

// MARK: - DataSourceError

enum DataSourceError: Error {
    case fileNotFound(String)
    case decodingFailed(String)
}
