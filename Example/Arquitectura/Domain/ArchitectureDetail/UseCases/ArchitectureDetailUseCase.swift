import Foundation

// MARK: - ArchitectureDetailUseCase

/// Protocol for getting a specific architecture feature detail by ID
protocol ArchitectureDetailUseCase: Sendable {
    /// Executes the use case to get detailed information for a specific feature
    /// - Parameter id: The feature ID
    /// - Returns: The architecture detail model if found, nil otherwise
    func execute(id: String) async throws -> ArchitectureDetailModel?
}
