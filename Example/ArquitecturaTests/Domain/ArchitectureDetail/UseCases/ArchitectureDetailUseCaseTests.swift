import Foundation
import Testing
@testable import Arquitectura

// MARK: - ArchitectureDetailUseCaseTests

@Suite
@MainActor
struct ArchitectureDetailUseCaseTests {
    // MARK: - Helper Methods

    private func makeDetailModel(id: String = "test-id",
                                 name: String = "Test Feature",
                                 icon: String = "building.2",
                                 version: String? = "1.0",
                                 category: ArchitectureDetailModel.Category = .architecture,
                                 subtitle: String = "Test subtitle",
                                 isImplemented: Bool = true,
                                 filesInvolved: [ArchitectureDetailModel.FileInfo] = [],
                                 implementationDetails: String = "Implementation details",
                                 codeExample: ArchitectureDetailModel.CodeExample? = nil,
                                 bestPractices: [ArchitectureDetailModel.BestPractice] = [])
        -> ArchitectureDetailModel {
        ArchitectureDetailModel(id: id,
                                name: name,
                                icon: icon,
                                version: version,
                                category: category,
                                subtitle: subtitle,
                                isImplemented: isImplemented,
                                filesInvolved: filesInvolved,
                                implementationDetails: implementationDetails,
                                codeExample: codeExample,
                                bestPractices: bestPractices)
    }

    // MARK: - Tests

    @Test("Execute returns feature from repository")
    func executeReturnsFeature() async throws {
        // Given
        let expectedFeature = makeDetailModel(id: "test-id",
                                              name: "Clean Architecture",
                                              subtitle: "A layered architecture pattern",
                                              isImplemented: true)

        let mockRepository = MockArchitectureDetailRepository()
        await mockRepository.setGetFeatureDetailResult(.success(expectedFeature))

        let useCase = ArchitectureDetailUseCaseImpl(repository: mockRepository)

        // When
        let result = try await useCase.execute(id: "test-id")

        // Then
        #expect(result?.id == expectedFeature.id)
        #expect(result?.name == expectedFeature.name)
    }

    @Test("Execute returns nil when feature not found")
    func executeReturnsNilWhenNotFound() async throws {
        // Given
        let mockRepository = MockArchitectureDetailRepository()
        await mockRepository.setGetFeatureDetailResult(.success(nil))

        let useCase = ArchitectureDetailUseCaseImpl(repository: mockRepository)

        // When
        let result = try await useCase.execute(id: "nonexistent-id")

        // Then
        #expect(result.isNil)
    }

    @Test("Execute calls repository with correct id")
    func executeCallsRepositoryWithCorrectId() async throws {
        // Given
        let mockRepository = MockArchitectureDetailRepository()
        await mockRepository.setGetFeatureDetailResult(.success(nil))

        let useCase = ArchitectureDetailUseCaseImpl(repository: mockRepository)
        let expectedId = "specific-feature-id"

        // When
        _ = try await useCase.execute(id: expectedId)

        // Then
        let lastId = await mockRepository.getFeatureDetailLastId
        #expect(lastId == expectedId)
        let callCount = await mockRepository.getFeatureDetailCallCount
        #expect(callCount == 1)
    }

    @Test("Execute maps repository error to DomainError")
    func executePropagatesError() async {
        // Given
        let expectedError = NSError(domain: "test", code: 42)
        let mockRepository = MockArchitectureDetailRepository()
        await mockRepository.setGetFeatureDetailResult(.failure(expectedError))

        let useCase = ArchitectureDetailUseCaseImpl(repository: mockRepository)

        // When/Then
        do {
            _ = try await useCase.execute(id: "test-id")
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error is DomainError)
            #expect(error as? DomainError == .unknown)
        }
    }
}
