import Foundation

// MARK: - ArchitectureRemoteDataSourceImpl

/// Implementation of ArchitectureRemoteDataSource with static data
/// In a real app, this would fetch data from an API using APIClient
struct ArchitectureRemoteDataSourceImpl: ArchitectureRemoteDataSource {
    // MARK: - Public Methods

    func fetchFeatures() async throws -> [ArchitectureDTO] {
        // Simulate async API call
        try await Task.sleep(for: .milliseconds(300))
        return Self.architectureFeatures
    }
}

// MARK: - Static Data

private extension ArchitectureRemoteDataSourceImpl {
    // MARK: - Architecture Features Data (DTOs simulating API response)

    static let architectureFeatures: [ArchitectureDTO] = [// Architecture
        ArchitectureDTO(id: "clean-architecture",
                        name: "Clean Architecture",
                        description: "Layered architecture with Domain, Data, and Presentation separation",
                        category: "architecture",
                        isImplemented: true),
        ArchitectureDTO(id: "mvvm",
                        name: "MVVM Pattern",
                        description: "Model-View-ViewModel with @Observable for reactive state management",
                        category: "architecture",
                        isImplemented: true),
        ArchitectureDTO(id: "router-pattern",
                        name: "Router Pattern",
                        description: "Centralized navigation with AppRouter and NavigationPath",
                        category: "architecture",
                        isImplemented: true),
        ArchitectureDTO(id: "dependency-injection",
                        name: "Dependency Injection",
                        description: "Factory-based DI without singletons for testability",
                        category: "architecture",
                        isImplemented: true),
        ArchitectureDTO(id: "feature-based",
                        name: "Feature-Based Organization",
                        description: """
                        Vertical slicing with 7 folders per feature (DI, Domain, Data, View, ViewModel, State, Router)
                        """,
                        category: "architecture",
                        isImplemented: true),

        // UI
        ArchitectureDTO(id: "swiftui",
                        name: "SwiftUI",
                        description: "Declarative UI framework for all views",
                        category: "ui",
                        isImplemented: true),
        ArchitectureDTO(id: "observable",
                        name: "@Observable (iOS 17+)",
                        description: "Modern observation framework replacing Combine's @Published",
                        category: "ui",
                        isImplemented: true),
        ArchitectureDTO(id: "design-tokens",
                        name: "Design System Tokens",
                        description: "Centralized colors, typography, and spacing in Core/DesignSystem",
                        category: "ui",
                        isImplemented: true),
        ArchitectureDTO(id: "view-modifiers",
                        name: "Reusable ViewModifiers",
                        description: "Extracted modifiers in Core/Common/SwiftUI/Modifiers",
                        category: "ui",
                        isImplemented: true),
        ArchitectureDTO(id: "state-separation",
                        name: "State Separation",
                        description: "ViewState enum in dedicated State/ folder, not inside ViewModel",
                        category: "ui",
                        isImplemented: true),

        // Networking
        ArchitectureDTO(id: "api-client",
                        name: "Centralized APIClient",
                        description: "Protocol-based HTTP client with generic request handling",
                        category: "networking",
                        isImplemented: true),
        ArchitectureDTO(id: "endpoint-builder",
                        name: "Endpoint Builder Pattern",
                        description: "Type-safe endpoint configuration with query params, headers, and body",
                        category: "networking",
                        isImplemented: true),
        ArchitectureDTO(id: "typed-errors",
                        name: "Typed API Errors",
                        description: "APIError enum with network, HTTP, decoding, and URL error cases",
                        category: "networking",
                        isImplemented: true),
        ArchitectureDTO(id: "error-mapping",
                        name: "Error Layer Mapping",
                        description: "APIError -> DomainError -> ErrorDecorator transformation chain",
                        category: "networking",
                        isImplemented: true),

        // Persistence
        ArchitectureDTO(id: "swiftdata",
                        name: "SwiftData Stack",
                        description: "ModelContainer configuration with background ModelExecutor support",
                        category: "persistence",
                        isImplemented: true),
        ArchitectureDTO(id: "background-executor",
                        name: "Background ModelExecutor",
                        description: "Isolated ModelContext for non-MainActor database operations",
                        category: "persistence",
                        isImplemented: true),

        // Security
        ArchitectureDTO(id: "ssl-pinning",
                        name: "SSL Certificate Pinning",
                        description: "Public key pinning via SSLPinningDelegate to prevent MITM attacks",
                        category: "security",
                        isImplemented: true),
        ArchitectureDTO(id: "environment-config",
                        name: "Environment Configuration",
                        description: "Dev/Staging/Production configs loaded from Info.plist via xcconfig",
                        category: "security",
                        isImplemented: true),

        // Testing
        ArchitectureDTO(id: "swift-testing",
                        name: "Swift Testing Framework",
                        description: "Modern testing with import Testing (not XCTest)",
                        category: "testing",
                        isImplemented: false),
        ArchitectureDTO(id: "testable-arch",
                        name: "Testable Architecture",
                        description: "Protocol-based dependencies enable easy mocking",
                        category: "testing",
                        isImplemented: true)]
}
