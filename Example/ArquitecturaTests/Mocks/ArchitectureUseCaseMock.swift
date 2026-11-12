import Foundation
@testable import Arquitectura

// MARK: - ArchitectureUseCaseMock

/// Mock implementation of ArchitectureUseCase for testing
@MainActor
final class ArchitectureUseCaseMock: ArchitectureUseCase {
    // MARK: - Properties

    var executeResult: Result<[ArchitectureModel], Error> = .success([])
    var executeCallCount = 0
    /// Runs once while the call is in flight, so a test can re-enter the caller deterministically.
    var onExecute: (() async -> Void)?

    // MARK: - ArchitectureUseCase

    func execute() async throws -> [ArchitectureModel] {
        executeCallCount += 1
        let hook = onExecute
        onExecute = nil
        await hook?()
        return try executeResult.get()
    }
}
