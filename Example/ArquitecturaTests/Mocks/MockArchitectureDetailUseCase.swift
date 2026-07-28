import Foundation
@testable import Arquitectura

// MARK: - MockArchitectureDetailUseCase

/// Mock implementation of ArchitectureDetailUseCase for testing
actor MockArchitectureDetailUseCase: ArchitectureDetailUseCase {
    // MARK: - Properties

    private(set) var executeResult: Result<ArchitectureDetailModel?, Error> = .success(nil)
    private(set) var executeCallCount = 0
    private(set) var executeLastId: String?

    // MARK: - Init

    init() {}

    // MARK: - Test Helpers

    func setExecuteResult(_ result: Result<ArchitectureDetailModel?, Error>) {
        executeResult = result
    }

    // MARK: - ArchitectureDetailUseCase

    func execute(id: String) async throws -> ArchitectureDetailModel? {
        executeCallCount += 1
        executeLastId = id

        switch executeResult {
        case let .success(feature):
            return feature
        case let .failure(error):
            throw error
        }
    }
}
