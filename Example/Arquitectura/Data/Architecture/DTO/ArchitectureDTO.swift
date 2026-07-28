import Foundation

// MARK: - ArchitectureDTO

/// Data Transfer Object for architecture features from API
/// Placeholder for future API integration
struct ArchitectureDTO: Codable {
    // MARK: - Properties

    let id: String
    let name: String
    let description: String
    let category: String
    let isImplemented: Bool

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case category
        case isImplemented = "is_implemented"
    }
}
