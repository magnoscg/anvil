import Foundation

// MARK: - ArchitectureRoute

/// Routes available within the Architecture feature.
/// Each feature defines its own route enum for type-safe navigation.
/// Must be Codable for state preservation with @SceneStorage.
enum ArchitectureRoute: Hashable, Codable {
    /// Navigate to feature detail view
    case detail(featureId: String)
}

// MARK: - ArchitectureRouter

/// Protocol for Architecture feature navigation.
/// ViewModels depend only on this protocol, not on AppRouter directly.
/// Must be Sendable for Swift 6 strict concurrency.
@MainActor
protocol ArchitectureRouter: Sendable {
    /// Navigates to the detail view for a specific feature
    /// - Parameter featureId: The ID of the feature to show details for
    func navigateToDetail(featureId: String)

    /// Goes back to the previous screen
    func goBack()
}

// MARK: - ArchitectureRouterImpl

/// Implementation of ArchitectureRouter that uses ArchitectureRoute enum
/// and delegates navigation to the generic AppRouter.
@MainActor
struct ArchitectureRouterImpl: ArchitectureRouter {
    // MARK: - Properties

    private let appRouter: AppRouter

    // MARK: - Init

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    // MARK: - Public Methods

    func navigateToDetail(featureId: String) {
        appRouter.push(ArchitectureRoute.detail(featureId: featureId))
    }

    func goBack() {
        appRouter.pop()
    }
}
