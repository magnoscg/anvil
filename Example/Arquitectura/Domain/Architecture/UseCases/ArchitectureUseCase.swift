import Foundation

// MARK: - ArchitectureUseCase

/// Protocol for the use case that retrieves architecture features
protocol ArchitectureUseCase: Sendable {
    /// Executes the use case to fetch all architecture features
    /// - Returns: Array of architecture models sorted by category
    func execute() async throws -> [ArchitectureModel]
}
