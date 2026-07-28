import Foundation
@testable import Arquitectura

// MARK: - MockArchitectureDetailRouter

/// Mock implementation of ArchitectureDetailRouter for testing
@MainActor
final class MockArchitectureDetailRouter: ArchitectureDetailRouter {
    // MARK: - Properties

    var navigateToPokemonListCallCount = 0
    var goBackCallCount = 0

    // MARK: - ArchitectureDetailRouter

    func navigateToPokemonList() {
        navigateToPokemonListCallCount += 1
    }

    func goBack() {
        goBackCallCount += 1
    }
}
