import Foundation
import SwiftUI

// MARK: - AppRouter

/// Feature-facing navigation API that accepts any Hashable & Codable route type.
/// Each feature defines its own route enum and uses this protocol to push and pop.
/// Features never read or replace the whole `NavigationPath`: only the App layer
/// (`RootNavigationView`, `AppNavigationCoordinator`) works with `AppRouterImpl.path`.
/// Must be Sendable for Swift 6 strict concurrency.
@MainActor
protocol AppRouter: Sendable {
    func push(_ route: some Hashable & Codable)
    func pop()
    func popToRoot()
}
