import Foundation
import SwiftUI

// MARK: - AppRouter

/// Generic router protocol that accepts any Hashable route type.
/// Each feature defines its own route enum and uses this protocol.
/// Must be Sendable for Swift 6 strict concurrency.
@MainActor
protocol AppRouter: Sendable {
    var path: NavigationPath { get set }
    func push(_ route: some Hashable & Codable)
    func pop()
    func popToRoot()
}
