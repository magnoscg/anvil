import Foundation

// MARK: - ArchitectureStaticDataSourceImpl

/// Implementation of ArchitectureStaticDataSource with embedded static data.
/// Contains all architecture features as hardcoded domain models.
struct ArchitectureStaticDataSourceImpl: ArchitectureStaticDataSource {
    // MARK: - Public Methods

    func getFeatures() -> [ArchitectureModel] {
        Self.architectureFeatures
    }

    func getFeature(id: String) -> ArchitectureModel? {
        Self.architectureFeatures.first { $0.id == id }
    }
}

// MARK: - Static Data

private extension ArchitectureStaticDataSourceImpl {
    // MARK: - Architecture Features Data

    static let architectureFeatures: [ArchitectureModel] = [ArchitectureModel(id: "clean-architecture",
                                                                              name: "Clean Architecture",
                                                                              description: "Layered architecture with Domain, Data, and Presentation separation",
                                                                              category: .architecture,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "mvvm",
                                                                              name: "MVVM Pattern",
                                                                              description: "Model-View-ViewModel with @Observable for reactive state management",
                                                                              category: .architecture,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "router-pattern",
                                                                              name: "Router Pattern",
                                                                              description: "Centralized navigation with AppRouter and NavigationPath",
                                                                              category: .architecture,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "dependency-injection",
                                                                              name: "Dependency Injection",
                                                                              description: "Factory-based DI without singletons for testability",
                                                                              category: .architecture,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "feature-based",
                                                                              name: "Feature-Based Organization",
                                                                              description: """
                                                                              Vertical slicing with 7 folders per feature (DI, Domain, Data, View, ViewModel, State, Router)
                                                                              """,
                                                                              category: .architecture,
                                                                              isImplemented: true,
                                                                              customIcon: nil),

                                                            ArchitectureModel(id: "swiftui",
                                                                              name: "SwiftUI",
                                                                              description: "Declarative UI framework for all views",
                                                                              category: .ui,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "observable",
                                                                              name: "@Observable (iOS 17+)",
                                                                              description: "Modern observation framework replacing Combine's @Published",
                                                                              category: .ui,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "design-tokens",
                                                                              name: "Design System Tokens",
                                                                              description: "Centralized colors, typography, and spacing in Core/DesignSystem",
                                                                              category: .ui,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "view-modifiers",
                                                                              name: "Reusable ViewModifiers",
                                                                              description: "Extracted modifiers in Core/Common/SwiftUI/Modifiers",
                                                                              category: .ui,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "state-separation",
                                                                              name: "State Separation",
                                                                              description: "ViewState enum in dedicated State/ folder, not inside ViewModel",
                                                                              category: .ui,
                                                                              isImplemented: true,
                                                                              customIcon: nil),

                                                            ArchitectureModel(id: "api-client",
                                                                              name: "Centralized APIClient",
                                                                              description: "Protocol-based HTTP client with generic request handling",
                                                                              category: .networking,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "endpoint-builder",
                                                                              name: "Endpoint Builder Pattern",
                                                                              description: "Type-safe endpoint configuration with query params, headers, and body",
                                                                              category: .networking,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "typed-errors",
                                                                              name: "Typed API Errors",
                                                                              description: "APIError enum with network, HTTP, decoding, and URL error cases",
                                                                              category: .networking,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "error-mapping",
                                                                              name: "Error Layer Mapping",
                                                                              description: "APIError -> DomainError -> ErrorDecorator transformation chain",
                                                                              category: .networking,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "pokemon-api",
                                                                              name: "Pokemon API Example",
                                                                              description: "Demonstrates API integration with PokeAPI using URLSession",
                                                                              category: .networking,
                                                                              isImplemented: false,
                                                                              customIcon: "pokeball"),

                                                            ArchitectureModel(id: "swiftdata",
                                                                              name: "SwiftData Stack",
                                                                              description: "ModelContainer configuration with background ModelExecutor support",
                                                                              category: .persistence,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "background-executor",
                                                                              name: "Background ModelExecutor",
                                                                              description: "Isolated ModelContext for non-MainActor database operations",
                                                                              category: .persistence,
                                                                              isImplemented: true,
                                                                              customIcon: nil),

                                                            ArchitectureModel(id: "ssl-pinning",
                                                                              name: "SSL Certificate Pinning",
                                                                              description: "Public key pinning via SSLPinningDelegate to prevent MITM attacks",
                                                                              category: .security,
                                                                              isImplemented: true,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "environment-config",
                                                                              name: "Environment Configuration",
                                                                              description: "Dev/Staging/Production configs loaded from Info.plist via xcconfig",
                                                                              category: .security,
                                                                              isImplemented: true,
                                                                              customIcon: nil),

                                                            ArchitectureModel(id: "swift-testing",
                                                                              name: "Swift Testing Framework",
                                                                              description: "Modern testing with import Testing (not XCTest)",
                                                                              category: .testing,
                                                                              isImplemented: false,
                                                                              customIcon: nil),
                                                            ArchitectureModel(id: "testable-arch",
                                                                              name: "Testable Architecture",
                                                                              description: "Protocol-based dependencies enable easy mocking",
                                                                              category: .testing,
                                                                              isImplemented: true,
                                                                              customIcon: nil)]
}
