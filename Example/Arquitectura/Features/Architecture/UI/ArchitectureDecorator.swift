import Foundation

// MARK: - ArchitectureSectionDecorator

/// Decorator representing a section of architecture features for UI
struct ArchitectureSectionDecorator: Equatable, Identifiable {
    // MARK: - Properties

    let id: String
    let title: String
    let icon: String
    let features: [ArchitectureItemDecorator]
}

// MARK: - ArchitectureItemDecorator

/// Decorator representing a single architecture feature for UI
struct ArchitectureItemDecorator: Equatable, Identifiable {
    // MARK: - Properties

    let id: String
    let name: String
    let description: String
    let icon: IconType
    let statusColor: StatusColor

    // MARK: - StatusColor

    enum StatusColor {
        case implemented
        case pending
    }
}
