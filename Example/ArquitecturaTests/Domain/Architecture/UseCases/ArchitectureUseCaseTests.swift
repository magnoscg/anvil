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
        // Given
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

        let mockRepository = MockArchitectureRepository()
        await mockRepository.setGetFeaturesResult(.success(unsortedFeatures))

        let useCase = ArchitectureUseCaseImpl(repository: mockRepository)

        // When
        let result = try await useCase.execute()

        // Then
        #expect(result.count == 3)
        #expect(result[0].category == .architecture)
        #expect(result[1].category == .security)
        #expect(result[2].category == .ui)
    }

    @Test("Execute calls repository once")
    func executeCallsRepositoryOnce() async throws {
        // Given
        let mockRepository = MockArchitectureRepository()
        await mockRepository.setGetFeaturesResult(.success([]))

        let useCase = ArchitectureUseCaseImpl(repository: mockRepository)

        // When
        _ = try await useCase.execute()

        // Then
        let callCount = await mockRepository.getFeaturesCallCount
        #expect(callCount == 1)
    }

    @Test("Execute maps repository error to DomainError")
    func executePropagatesError() async {
        // Given
        let expectedError = NSError(domain: "test", code: 42)
        let mockRepository = MockArchitectureRepository()
        await mockRepository.setGetFeaturesResult(.failure(expectedError))

        let useCase = ArchitectureUseCaseImpl(repository: mockRepository)

        // When/Then
        do {
            _ = try await useCase.execute()
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error is DomainError)
            #expect(error as? DomainError == .unknown)
        }
    }
}
