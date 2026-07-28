import Foundation
@testable import Arquitectura

// MARK: - MockArchitectureRepository

/// Mock implementation of ArchitectureRepository for testing
actor MockArchitectureRepository: ArchitectureRepository {
    // MARK: - Properties

    private(set) var getFeaturesResult: Result<[ArchitectureModel], Error> = .success([])
    private(set) var getFeaturesCallCount = 0

    private(set) var getFeatureResult: Result<ArchitectureModel?, Error> = .success(nil)
    private(set) var getFeatureCallCount = 0
    private(set) var getFeatureLastId: String?

    // MARK: - Init

    init() {}

    // MARK: - Test Helpers

    func setGetFeaturesResult(_ result: Result<[ArchitectureModel], Error>) {
        getFeaturesResult = result
    }

    func setGetFeatureResult(_ result: Result<ArchitectureModel?, Error>) {
        getFeatureResult = result
    }

    // MARK: - ArchitectureRepository

    func getFeatures() async throws -> [ArchitectureModel] {
        getFeaturesCallCount += 1

        switch getFeaturesResult {
        case let .success(features):
            return features
        case let .failure(error):
            throw error
        }
    }

    func getFeature(id: String) async throws -> ArchitectureModel? {
        getFeatureCallCount += 1
        getFeatureLastId = id

        switch getFeatureResult {
        case let .success(feature):
            return feature
        case let .failure(error):
            throw error
        }
    }
}
