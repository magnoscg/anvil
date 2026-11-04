import Foundation

// MARK: - ArchitectureDetailResponseDTO

/// Root DTO for the architecture details JSON response.
/// DTOs are `nonisolated` and `Sendable` so the bundled file can be decoded off the main actor.
nonisolated struct ArchitectureDetailResponseDTO: Codable, Sendable {
    let features: [ArchitectureDetailDTO]
}

// MARK: - ArchitectureDetailDTO

/// Data Transfer Object for architecture feature details from JSON
nonisolated struct ArchitectureDetailDTO: Codable, Sendable {
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
}

// MARK: - FileInfoDTO

nonisolated struct FileInfoDTO: Codable, Sendable {
    let name: String
    let icon: String
}

// MARK: - CodeExampleDTO

nonisolated struct CodeExampleDTO: Codable, Sendable {
    let language: String
    let code: String
}

// MARK: - BestPracticeDTO

nonisolated struct BestPracticeDTO: Codable, Sendable {
    let id: String
    let title: String
    let description: String
}
