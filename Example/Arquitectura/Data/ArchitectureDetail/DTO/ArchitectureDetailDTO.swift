import Foundation

// MARK: - ArchitectureDetailResponseDTO

/// Root DTO for the architecture details JSON response
struct ArchitectureDetailResponseDTO: Codable {
    let features: [ArchitectureDetailDTO]
}

// MARK: - ArchitectureDetailDTO

/// Data Transfer Object for architecture feature details from JSON
struct ArchitectureDetailDTO: Codable {
    // MARK: - Properties

    let id: String
    let name: String
    let icon: String
    let version: String?
    let category: String
    let subtitle: String
    let isImplemented: Bool
    let filesInvolved: [FileInfoDTO]
    let implementationDetails: String
    let codeExample: CodeExampleDTO?
    let bestPractices: [BestPracticeDTO]

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case version
        case category
        case subtitle
        case isImplemented
        case filesInvolved
        case implementationDetails
        case codeExample
        case bestPractices
    }
}

// MARK: - FileInfoDTO

struct FileInfoDTO: Codable {
    let name: String
    let icon: String
}

// MARK: - CodeExampleDTO

struct CodeExampleDTO: Codable {
    let language: String
    let code: String
}

// MARK: - BestPracticeDTO

struct BestPracticeDTO: Codable {
    let id: String
    let title: String
    let description: String
}
