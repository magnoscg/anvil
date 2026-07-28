import SwiftUI

// MARK: - ArchitectureRouteResolver

/// ViewModifier that resolves ArchitectureRoute destinations.
/// Each feature defines its own resolver for its routes.
struct ArchitectureRouteResolver: ViewModifier {
    // MARK: - Properties

    let appRouter: AppRouter

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: ArchitectureRoute.self) { route in
                destination(for: route)
            }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func destination(for route: ArchitectureRoute) -> some View {
        switch route {
        case let .detail(featureId):
            ArchitectureDetailFactory.makeView(featureId: featureId,
                                               appRouter: appRouter)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies Architecture feature route resolution to the view.
    /// - Parameter appRouter: The app router instance
    /// - Returns: View with Architecture routes resolved
    func withArchitectureRoutes(appRouter: AppRouter) -> some View {
        modifier(ArchitectureRouteResolver(appRouter: appRouter))
    }
}
