import Foundation
@testable import Arquitectura

// MARK: - MockArchitectureRouter

/// Mock implementation of ArchitectureRouter for testing
@MainActor
final class MockArchitectureRouter: ArchitectureRouter {
    // MARK: - Properties

    var navigateToDetailFeatureId: String?
    var navigateToDetailCallCount = 0
    var goBackCallCount = 0

    // MARK: - ArchitectureRouter

    func navigateToDetail(featureId: String) {
        navigateToDetailFeatureId = featureId
        navigateToDetailCallCount += 1
    }

    func goBack() {
        goBackCallCount += 1
    }
}
