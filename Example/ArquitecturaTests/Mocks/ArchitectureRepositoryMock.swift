import Foundation
@testable import Arquitectura

// MARK: - ArchitectureRepositoryMock

/// Mock implementation of ArchitectureRepository for testing
@MainActor
final class ArchitectureRepositoryMock: ArchitectureRepository {
    // MARK: - Properties

    var getFeaturesResult: Result<[ArchitectureModel], Error> = .success([])
    var getFeaturesCallCount = 0

    var getFeatureResult: Result<ArchitectureModel?, Error> = .success(nil)
    var getFeatureCallCount = 0
    var getFeatureLastId: String?

    // MARK: - ArchitectureRepository

    func getFeatures() async throws -> [ArchitectureModel] {
        getFeaturesCallCount += 1
        return try getFeaturesResult.get()
    }

    func getFeature(id: String) async throws -> ArchitectureModel? {
        getFeatureCallCount += 1
        getFeatureLastId = id
        return try getFeatureResult.get()
    }
}
