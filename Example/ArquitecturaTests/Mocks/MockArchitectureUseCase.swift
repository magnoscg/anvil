import Foundation
@testable import Arquitectura

// MARK: - MockArchitectureUseCase

/// Mock implementation of ArchitectureUseCase for testing
actor MockArchitectureUseCase: ArchitectureUseCase {
    // MARK: - Properties

    private(set) var executeResult: Result<[ArchitectureModel], Error> = .success([])
    private(set) var executeCallCount = 0

    // MARK: - Init

    init() {}

    // MARK: - Test Helpers

    func setExecuteResult(_ result: Result<[ArchitectureModel], Error>) {
        executeResult = result
    }

    // MARK: - ArchitectureUseCase

    func execute() async throws -> [ArchitectureModel] {
        executeCallCount += 1

        switch executeResult {
        case let .success(features):
            return features
        case let .failure(error):
            throw error
        }
    }
}
