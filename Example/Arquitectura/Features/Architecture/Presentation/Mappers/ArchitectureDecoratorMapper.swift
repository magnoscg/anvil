import Foundation

// MARK: - ArchitectureDecoratorMapper

/// Protocol for mapping Domain models to UI Decorators.
/// Pure data transformation — no actor isolation needed.
protocol ArchitectureDecoratorMapper: Sendable {
    /// Maps a domain model to a UI decorator
    /// - Parameter model: The domain model to map
    /// - Returns: The mapped UI decorator
    func map(_ model: ArchitectureModel) -> ArchitectureItemDecorator

    /// Maps an array of domain models to grouped sections for UI
    /// - Parameter models: The domain models to map
    /// - Returns: Array of section decorators grouped by category
    func mapToSections(_ models: [ArchitectureModel]) -> [ArchitectureSectionDecorator]
}
