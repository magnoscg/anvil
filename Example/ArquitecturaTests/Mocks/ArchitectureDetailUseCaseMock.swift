import Foundation
@testable import Arquitectura

// MARK: - ArchitectureDetailUseCaseMock

/// Mock implementation of ArchitectureDetailUseCase for testing
final class ArchitectureDetailUseCaseMock: ArchitectureDetailUseCase {
    // MARK: - Properties

    var executeResult: Result<ArchitectureDetailModel?, Error> = .success(nil)
    var executeCallCount = 0
    var executeLastId: String?
    /// Runs once while the call is in flight, so a test can re-enter the caller deterministically.
    var onExecute: (() async -> Void)?

    // MARK: - ArchitectureDetailUseCase

    func execute(id: String) async throws -> ArchitectureDetailModel? {
        executeCallCount += 1
        executeLastId = id
        let hook = onExecute
        onExecute = nil
        await hook?()
        return try executeResult.get()
    }
}
