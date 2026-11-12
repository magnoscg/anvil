import Foundation
import Testing
@testable import Arquitectura

// MARK: - ArchitectureUseCaseTests

@Suite
@MainActor
struct ArchitectureUseCaseTests {
    // MARK: - Tests

    @Test("Execute returns features sorted by category")
    func executeReturnsSortedFeatures() async throws {
        let unsortedFeatures = [ArchitectureModel(id: "3",
                                                  name: "SwiftUI",
                                                  description: "UI",
                                                  category: .ui,
                                                  isImplemented: true,
                                                  customIcon: nil),
                                ArchitectureModel(id: "1",
                                                  name: "Clean Architecture",
                                                  description: "Architecture",
                                                  category: .architecture,
                                                  isImplemented: true,
                                                  customIcon: nil),
                                ArchitectureModel(id: "2",
                                                  name: "SSL Pinning",
                                                  description: "Security",
                                                  category: .security,
                                                  isImplemented: true,
                                                  customIcon: nil)]
        let mockRepository = ArchitectureRepositoryMock()
        mockRepository.getFeaturesResult = .success(unsortedFeatures)
        let useCase = ArchitectureUseCaseImpl(repository: mockRepository)

        let result = try await useCase.execute()

        #expect(result.count == 3)
        #expect(result[0].category == .architecture)
        #expect(result[1].category == .security)
        #expect(result[2].category == .ui)
    }

    @Test("Execute calls repository once")
    func executeCallsRepositoryOnce() async throws {
        let mockRepository = ArchitectureRepositoryMock()
        mockRepository.getFeaturesResult = .success([])
        let useCase = ArchitectureUseCaseImpl(repository: mockRepository)

        _ = try await useCase.execute()

        #expect(mockRepository.getFeaturesCallCount == 1)
    }

    @Test("Execute propagates the repository's DomainError")
    func executePropagatesError() async {
        let mockRepository = ArchitectureRepositoryMock()
        mockRepository.getFeaturesResult = .failure(DomainError.network)
        let useCase = ArchitectureUseCaseImpl(repository: mockRepository)

        await #expect(throws: DomainError.network) { try await useCase.execute() }
    }
}
