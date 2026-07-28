import Foundation
import SwiftUI

// MARK: - AppRouterImpl

/// Implementation of AppRouter using NavigationPath.
@MainActor
@Observable
final class AppRouterImpl: AppRouter {
    // MARK: - Properties

    var path = NavigationPath()

    // MARK: - Public Methods

    /// Pushes any Hashable route onto the navigation stack.
    /// Each feature uses its own route enum type.
    func push(_ route: some Hashable & Codable) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        guard !path.isEmpty else { return }
        path = NavigationPath()
    }
}
