import Foundation

// MARK: - ArchitectureDetailModel

/// Domain model representing detailed information about an architecture feature
struct ArchitectureDetailModel: Equatable, Identifiable {
    // MARK: - Properties

    let id: String
    let name: String
    let icon: String
    let version: String?
    let category: Category
    let subtitle: String
    let isImplemented: Bool
    let filesInvolved: [FileInfo]
    let implementationDetails: String
    let codeExample: CodeExample?
    let bestPractices: [BestPractice]

    // MARK: - Category

    enum Category: String, Codable, CaseIterable {
        case architecture
        case ui
        case networking
        case persistence
        case security
        case testing
    }

    // MARK: - FileInfo

    struct FileInfo: Equatable, Codable, Identifiable {
        let id: String
        let name: String
        let icon: String

        init(id: String = UUID().uuidString, name: String, icon: String) {
            self.id = id
            self.name = name
            self.icon = icon
        }
    }

    // MARK: - CodeExample

    struct CodeExample: Equatable, Codable {
        let language: String
        let code: String
    }

    // MARK: - BestPractice

    struct BestPractice: Equatable, Codable, Identifiable {
        let id: String
        let title: String
        let description: String
    }
}
