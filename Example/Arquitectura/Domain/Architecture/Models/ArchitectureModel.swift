import Foundation

// MARK: - ArchitectureModel

/// Domain model representing an architecture feature of the project
struct ArchitectureModel: Equatable, Identifiable {
    // MARK: - Properties

    let id: String
    let name: String
    let description: String
    let category: Category
    let isImplemented: Bool
    let customIcon: String?

    // MARK: - Category

    enum Category: String, CaseIterable {
        case architecture = "Architecture"
        case ui = "UI"
        case networking = "Networking"
        case persistence = "Persistence"
        case security = "Security"
        case testing = "Testing"
    }
}
