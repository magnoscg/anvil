import Foundation
@testable import Arquitectura

// MARK: - ArchitectureDetailRepositoryMock

/// Mock implementation of ArchitectureDetailRepository for testing
@MainActor
final class ArchitectureDetailRepositoryMock: ArchitectureDetailRepository {
    // MARK: - Properties

    var getFeatureDetailResult: Result<ArchitectureDetailModel?, Error> = .success(nil)
    var getFeatureDetailCallCount = 0
    var getFeatureDetailLastId: String?

    // MARK: - ArchitectureDetailRepository

    func getFeatureDetail(id: String) async throws -> ArchitectureDetailModel? {
        getFeatureDetailCallCount += 1
        getFeatureDetailLastId = id
        return try getFeatureDetailResult.get()
    }
}
