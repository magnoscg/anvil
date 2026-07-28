import Foundation

// MARK: - ArchitectureDetailDecoratorMapper

/// Protocol for mapping domain model to detail decorator
protocol ArchitectureDetailDecoratorMapper: Sendable {
    /// Maps a domain model to a detail decorator
    /// - Parameter model: The domain model to map
    /// - Returns: The mapped detail decorator
    func map(_ model: ArchitectureDetailModel) -> ArchitectureDetailDecorator
}
