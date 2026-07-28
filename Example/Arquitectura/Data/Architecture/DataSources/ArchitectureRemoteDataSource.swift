import Foundation

// MARK: - ArchitectureRemoteDataSource

/// Protocol for remote data source that fetches architecture features from API
/// Returns DTOs that must be mapped to domain models by the repository
protocol ArchitectureRemoteDataSource: Sendable {
    /// Fetches architecture features from remote source
    /// - Returns: Array of architecture DTOs
    func fetchFeatures() async throws -> [ArchitectureDTO]
}
