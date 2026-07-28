import Foundation
@testable import Arquitectura

// MARK: - MockArchitectureDetailRepository

/// Mock implementation of ArchitectureDetailRepository for testing
actor MockArchitectureDetailRepository: ArchitectureDetailRepository {
    // MARK: - Properties

    private(set) var getFeatureDetailResult: Result<ArchitectureDetailModel?, Error> = .success(nil)
    private(set) var getFeatureDetailCallCount = 0
    private(set) var getFeatureDetailLastId: String?

    // MARK: - Init

    init() {}

    // MARK: - Test Helpers

    func setGetFeatureDetailResult(_ result: Result<ArchitectureDetailModel?, Error>) {
        getFeatureDetailResult = result
    }

    // MARK: - ArchitectureDetailRepository

    func getFeatureDetail(id: String) async throws -> ArchitectureDetailModel? {
        getFeatureDetailCallCount += 1
        getFeatureDetailLastId = id

        switch getFeatureDetailResult {
        case let .success(feature):
            return feature
        case let .failure(error):
            throw error
        }
    }
}
